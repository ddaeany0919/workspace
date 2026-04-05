#!/usr/bin/env bash
DEF_SLEEP=5;
function getResult() {
    read -t $DEF_SLEEP -p "No problem! timeout:$DEF_SLEEP, (Y/y) " result;
    result=`echo $result | tr '[:upper:]' '[:lower:]'`
    if [ "$result" == "y" ] || [ -z "$result" ]; then
        echo ""
        exit 0;
    else
        select index in "Check HDCP state" "Display black" "No Sound" "Crazy screen" "Direct report" "Next step"; do
            case $index in
                Check*)
                test_dist hdcp state
                ;;
                "Direct report")
                    read -p "    Problem: " result;
                    break;
                ;;
                "Display black" | "No Sound" | "Crazy screen")
                    result=$index
                    break;
                ;;
                "Next step")
                    result="";
                    break;
                ;;
                *)
                    echo "index=$index"
                    result=$index
                    break;
                ;;
                
            esac
        done
    fi;
    echo "$result";
    exit 0;
}
echo "Is OK and next setp"
result=`getResult`;
if [ "$result" != "" ]; then
    echo "result = $result"
fi
