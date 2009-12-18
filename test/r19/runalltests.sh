#!/bin/bash
#
for backup in $(ls $(pwd)/test/*~)
do
  rm $backup
done
#
echo "==== Run All Tests ===="
for test in $(ls $(pwd)/test/test_0*)
do
  echo $test
  ruby -I $(pwd)/lib $test $*
done

