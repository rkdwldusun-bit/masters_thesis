# R 스타일 개정본

최신 검토 대상은 빌드 성공을 확인한 Chapter5_RStyle.docx입니다. 기존 Chapter5_Revised.docx는 보존합니다.

첨부 우수논문의 표 예시를 따라 가로선 중심, 음영 없음, 이탤릭 제목·패널, 결과변수별 열로 구성합니다. 그림은 기존 R/00_theme_thesis.R를 사용합니다. Arial Narrow가 없으면 저장소 규칙대로 Nimbus Sans Narrow를 사용합니다.

수정된 PDF 출력은 임시 파일에 그린 뒤 장치를 명시적으로 닫고, 크기를 확인한 후 최종 파일로 복사합니다. Python 검증은 네 PDF 모두 실제로 열어 페이지·텍스트·렌더링을 확인합니다. 이는 발견한 빈 PDF 파일에 대한 재발 방지 조치이며, 종전 오류의 원인을 확정한 것은 아닙니다.

## 재현

저장소 루트에서 R(ggplot2, data.table), Python(pandas, numpy, python-docx, Pillow, PyMuPDF), pandoc, LibreOffice가 필요합니다.

```bash
Rscript chapter5_revision_20261001/R/render_chapter5.R
python chapter5_revision_20261001/build_chapter_rstyle.py
mkdir -p chapter5_revision_20261001/qa_rstyle
libreoffice --headless --convert-to pdf --outdir chapter5_revision_20261001/qa_rstyle chapter5_revision_20261001/Chapter5_RStyle.docx
python chapter5_revision_20261001/check_rstyle.py
```

이 작업은 저장된 결과의 표현을 변경합니다. 새 효과·SE·p-value, bootstrap 및 모의실험은 계산하지 않습니다. 기술통계 SD와 추론용 SE를 구분하고 기존 인과·추론 한계를 유지합니다.

## 복구 및 검증 상태

로컬 환경 중단 전 R 그림 4개, Word 23쪽, 수치 대조 40건을 확인했습니다. 다만 부록 별도 PDF가 빈 파일이어서 전체 패키지를 최종 완료로 볼 수 없었습니다. 현재 코드는 GitHub의 기존 빌더와 대화에 보존된 수정사항으로 복구했으며, GitHub Actions 실행에서 53개 검사를 통과했습니다. 네 PDF가 실제로 열리고 렌더링됨을 확인했습니다. Word는 23쪽이며 편집 가능한 수식 30개가 유지됩니다. 실행 로그와 outputs/rstyle_validation.json에 기록했습니다. 이전 실행 결과를 새 코드의 실행 결과로 대신하지 않습니다.

외부 검토자는 최신 파일명으로 갱신한 REVIEW_HANDOFF_KO.md의 요청문을 사용하십시오. 원본 우수논문이나 기관 원문 PDF는 이 변경에 공개 업로드하지 않습니다.
