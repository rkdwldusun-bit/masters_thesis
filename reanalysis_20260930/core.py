"""Exact linear contrasts, score maps, and a weighted stacked regression.
No package-specific estimator is claimed. See PLAN.md for estimands and limitations.
"""
from pathlib import Path
import sys
import numpy as np
import pandas as pd
from scipy import stats

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'reanalysis_20260929'))
import original_engine as E
ANN = ['soybean','onion','sweet_potato','corn','garlic','spring_potato','red_pepper']
OUTCOMES = ['ln_area','ln_yield','ln_production']
SEED = 20260930

class Design:
    def __init__(self, panel, outcome, controls, events=range(10)):
        self.P=panel; self.outcome=outcome; self.events=list(events)
        D,Y,meta=E.prepare(panel,outcome,ANN,controls)
        self.D,self.Y,self.meta=D,Y,meta
        self.cells=list(Y); self.ix={k:i for i,k in enumerate(self.cells)}
        self.y=np.array(list(Y.values())); n=len(Y)
        self.crops=sorted(D.crop_id.unique()); G=len(self.crops)
        self.ci={c:i for i,c in enumerate(self.crops)}
        self.groups=np.array([self.ci[c] for c,t in self.cells])
        ag=E.cs_weights(D,Y,meta,ANN,e_post=events)
        self.ag=ag; self.weights={}
        for e,a in ag.items():
            z=np.zeros(n)
            for k,v in a['w'].items(): z[self.ix[k]]=v
            self.weights[e]=z
        es=[e for e in events if e in ag]
        assert len(es)==len(events)
        self.w=np.mean([self.weights[e] for e in es],axis=0)
        U=list(zip(D.loc[D.clean,'crop_id'],D.loc[D.clean,'year']))
        _,_,XU,cs,ts,ci,ti=E.fe_fit(D,Y,U)
        XA=np.zeros((n,XU.shape[1]))
        for j,(c,t) in enumerate(self.cells):
            XA[j,ci[c]]=1
            if ti[t]>0: XA[j,len(cs)+ti[t]-1]=1
        self.clean_ix=np.array([self.ix[k] for k in U])
        self.fe_pinv=np.linalg.pinv(XU)
        self.fe_design=XA
        M=np.eye(n); M[:,self.clean_ix]-=XA@self.fe_pinv
        self.Mclean=M.copy()
        for r in D[D.post].itertuples():
            e=int(r.year-r.g)
            if e in self.weights: M[self.ix[r.crop_id,r.year]]-=self.weights[e]
        self.M=M
        A=np.zeros((G,n))
        for j in range(G): A[j,self.groups==j]=self.w[self.groups==j]
        self.L=A@M
        self.active=np.flatnonzero(np.any(abs(A)>1e-14,axis=1))
        self.G=len(self.active); self.cr1=self.G/(self.G-1)
        # Exact stacked differences: balanced treated/donor mass in each stratum.
        clean=set(U); crops=list(meta.index); rows=[]; strata=[]; pairs=[]
        for e in es:
            for i in ag[e]['crops']:
                b=max(t for c,t in clean if c==i); t=int(meta.loc[i,'g']+e)
                J=[j for j in crops if j!=i and (j,b) in clean and (j,t) in clean]
                q=1/(len(es)*ag[e]['n_tr']); s=len(strata)
                strata.append((i,e,b,t,J,q))
                for c,weight,x in [(i,q,1)]+[(j,q/len(J),0) for j in J]:
                    rows.append((s,self.ci[c],weight,x)); pairs.append((self.ix[c,t],self.ix[c,b]))
        self.strata=strata
        R=np.array(rows); self.rs=R[:,0].astype(int); self.rc=R[:,1].astype(int)
        self.rweight=R[:,2]; self.x=R[:,3]; self.xt=self.x-.5
        nr=len(rows); ns=len(strata)
        B=np.zeros((nr,n))
        for j,(a,b) in enumerate(pairs): B[j,a]=1; B[j,b]=-1
        self.B=B; self.h=2*self.rweight*self.xt
        Q=np.zeros((ns,n)); H=np.zeros((G,ns))
        for r,(s,c,weight,x) in enumerate(rows):
            Q[s]+=weight/(2*strata[s][5])*B[r]
            H[c,s]+=self.h[r]
        self.Q=Q; self.H=H
        self.U0=B-Q[self.rs]
        self.U1=self.U0-self.xt[:,None]*self.w
        LB=np.zeros((G,n)); LC=np.zeros((G,G,n)); d=np.zeros(G)
        for r,(s,c,weight,x) in enumerate(rows):
            LB[c]+=self.h[r]*self.U0[r]
            LC[:,c]-=H[:,s,None]*(weight/(2*strata[s][5]))*self.U0[r]
            d[c]+=self.h[r]*self.xt[r]
        for c in range(G): LC[c,c]+=LB[c]
        LC-=d[:,None,None]*LB[None,:,:]
        self.LB=LB; self.LC=LC; self.d=d
        self.LS=LB-d[:,None]*self.w
        self.weight_error=float(np.max(abs(self.h@B-self.w)))
        assert self.weight_error<1e-12
        # Mean crop contrast map (only equal to theta for complete event panels).
        cropmaps=[]
        for i in ANN:
            ids=[s for s,z in enumerate(strata) if z[0]==i]
            assert len(ids)==len(es), 'Seven-mean method requires full event support'
            z=np.zeros(n)
            for s in ids:
                i,e,b,t,J,q=strata[s]
                z[self.ix[i,t]]+=1/len(ids); z[self.ix[i,b]]-=1/len(ids)
                for j in J:
                    z[self.ix[j,t]]-=1/(len(ids)*len(J)); z[self.ix[j,b]]+=1/(len(ids)*len(J))
            cropmaps.append(z)
        self.cropmap=np.array(cropmaps)
        assert np.max(abs(self.cropmap.mean(axis=0)-self.w))<1e-12
        assert np.max(abs(self.w@XA))<1e-12

    def original(self, y, V):
        theta=self.w@y; psi=self.L@y; star=V@psi
        q=np.quantile(abs(star),.95); se=np.sqrt(self.cr1*(psi@psi))
        return dict(est=theta,se=se,ci_lo=theta-q,ci_hi=theta+q,p=(1+np.sum(abs(star)>=abs(theta)))/(len(V)+1))

    def stacked(self,y,V):
        theta=self.w@y; score=self.LS@y; se=np.sqrt(self.cr1*(score@score))
        b=self.LB@y; C=self.LC@y
        bst=V@b; sest=np.sqrt(self.cr1*np.sum((V@C.T)**2,axis=1))
        p=(1+np.sum(abs(bst/sest)>=abs(theta/se)))/(len(V)+1)
        q=stats.t.ppf(.975,self.G-1)
        return dict(est=theta,se=se,ci_lo=theta-q*se,ci_hi=theta+q*se,p=p)

    def t7(self,y):
        v=self.cropmap@y; theta=v.mean(); se=v.std(ddof=1)/np.sqrt(7); q=stats.t.ppf(.975,6)
        return dict(est=theta,se=se,ci_lo=theta-q*se,ci_hi=theta+q*se,p=2*stats.t.sf(abs(theta/se),6))

    def check(self):
        """Literal WLS and bootstrap refits, plus original score map on synthetic data."""
        rng=np.random.default_rng(SEED+12); checks=[]
        X=np.column_stack([self.x,np.eye(len(self.strata))[self.rs]])
        Xw=X*np.sqrt(self.rweight)[:,None]; pinv=np.linalg.pinv(Xw)
        for trial in range(3):
            y=rng.standard_normal(len(self.y)); dy=self.B@y
            beta=pinv@(dy*np.sqrt(self.rweight)); resid=dy-X@beta
            scores=np.bincount(self.rc,weights=self.h*resid,minlength=len(self.crops))
            checks.append(max(abs(beta[0]-self.w@y),np.max(abs(scores-self.LS@y))))
            v=rng.choice(E.WEBB,len(self.crops))
            star=(self.Q@y)[self.rs]+v[self.rc]*(self.U0@y)
            bs=pinv@(star*np.sqrt(self.rweight)); us=star-X@bs
            ss=np.bincount(self.rc,weights=self.h*us,minlength=len(self.crops))
            checks.append(max(abs(bs[0]-v@(self.LB@y)),np.max(abs(ss-(self.LC@y)@v))))
            Ys=dict(zip(self.cells,y)); att={e:z@y for e,z in self.weights.items()}
            res=E.residuals(self.D,Ys,att)
            ps=np.zeros(len(self.crops))
            for k,w in zip(self.cells,self.w): ps[self.ci[k[0]]]+=w*res[k]
            checks.append(np.max(abs(ps-self.L@y)))
        assert max(checks)<1e-10,max(checks)
        return max(checks)

def wilson(k,n):
    p=k/n; z=stats.norm.ppf(.975); d=1+z*z/n
    center=(p+z*z/(2*n))/d; half=z*np.sqrt(p*(1-p)/n+z*z/(4*n*n))/d
    return center-half,center+half
