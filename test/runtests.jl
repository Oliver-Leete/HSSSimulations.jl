using TestItemRunner

cd("../")

@run_package_tests filter = ti -> !(:skipci in ti.tags)
