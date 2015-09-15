#!/bin/ksh
#set -x
##
#initialise variables
predictions_output_dir='/archive/volumes'
ampod_pred_file=$(ls -lt $predictions_output_dir | awk 'FNR==2 { print $NF }')
##
#initialise an array to hold the required field names
set -A field_names "Direct Debit Uploads" "Meter Reads  " "Estimated bills" "Refunds" "Debt Recovery Letters" "Active Accounts"    \
                   "Meter Reroutes" "WFM's" "Field Orders" "Counterpart Reads" "Exceptional Meter Reads" "Number of D149 Files"    \
                   "Number of D10 Files" "Unmapped MSID's" "Number of D4 Files" "Number of Cash items in suspense"
##
#create the batch predictions file
echo "\c" > batch_predictions
##
cnt=0
for field in "${field_names[@]}"; do
        #extract the requrired values to a file
        cat $predictions_output_dir/$ampod_pred_file | grep "$field" | \
        awk '{ printf("%s ", $NF",") }' >> batch_predictions
        cpb atch_predictions absolute_shyte
        echo >> absolute_shyte
done
                cat absolute_shyte | awk -F, '{ for(cnt=1;cnt<=5;cnt++)
                                                        { printf("%s,",$cnt) }
                                                        printf("3000,")
                                                    for(cnt=6;cnt<=16;cnt++)
                                                        { printf("%s,",$cnt) }
                                                        printf("\n")
                                                        }' > batch_predictions
