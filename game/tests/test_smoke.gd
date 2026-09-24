extends GutTest

## Trivial smoke test proving the headless GUT pipeline is wired end to end:
## install -> import -> gut_cmdln discovers and runs this test -> exit
## propagates correctly.


func test_gut_pipeline_is_wired():
	assert_eq(1 + 1, 2, "Arithmetic should still work inside GUT.")
