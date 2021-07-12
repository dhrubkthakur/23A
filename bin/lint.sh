#!/usr/bin/env bash
 
# For module imports
echo "flake8... "
if ! flake8 "./src" "./test"; then
    fail=$(($fail + 1))
fi
echo "Result: ${fail}"
 
echo "pylint..."
if ! pylint -E `find ./src  ./test -name '*.py'`; then
    fail=$(($fail + 1))
fi
echo "Result: ${fail}"
 
echo "isort..."
if ! isort -c `find ./src ./test -name '*.py'`; then
    fail=$(($fail + 1))
fi
echo "Result: ${fail}"
 
exit $fail

