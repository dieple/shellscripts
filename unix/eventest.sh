

PARAMETER=$1

eventest(){

ORIGINAL=$1

TEST=$(bc <<!

$ORIGINAL / 2 * 2

!)

CHECK=$(expr $ORIGINAL - $TEST)

if [ $CHECK -eq 0 ]

then

echo "Even"

else

echo "Odd"

fi

}
