set(CTEST_PROJECT_NAME "SlicerTranslated")
set(CTEST_NIGHTLY_START_TIME "3:00:00 UTC")

if(NOT DEFINED CDASH_PROJECT_NAME)
  set(CDASH_PROJECT_NAME "SlicerPreview")
endif()

set(CTEST_DROP_METHOD "http")
set(CTEST_DROP_SITE "jerry.iuibs.ulpgc.es")
set(CTEST_DROP_LOCATION "/CDash-pruebas/submit.php?project=${CDASH_PROJECT_NAME}")
set(CTEST_DROP_SITE_CDASH TRUE)

