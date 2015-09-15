#*************************************************************************
> ******
> #
> # FUNCTION:     sender
> #
> # DESCRIPTION:
> #               Transfer Mondays blank html documents to batch 
predictions
> #               intranet directory.
> #
> #
> 
#*************************************************************************
> ******
> sender(){
> cd $BASEDIR
> HOST="10.16.7.4"
> ftp -ni $HOST <<! 2> /dev/null
> user "$USERNAME" "$PASSWORD"
> cd Am
> cd predict
> cd html
> mput *.htm
> bye
> !
> }

