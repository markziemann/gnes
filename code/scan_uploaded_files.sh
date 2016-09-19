#!/bin/bash

################################################################################
#
# scan_uploaded_files.sh simply screens the contents of Excel spreadsheets for
# gene name errors.
#
# by Mark Ziemann email:mark.ziemann@gmail.com
VERSION=v0.1
#
################################################################################

#set -x
#Gene lists are necessary to determine whether input data are also gene lists
#Gene lists specified here MUST have the _genes suffix
GENELIST_DIR=`pwd`/'genelists/'

## scanit is function that screens Excel files for gene name errors.
scanit(){
#set -x
DATE=`date -u +%Y-%m-%d`	#Record the date for record-keeping purposes
FILE=$1
cp $FILE .
FILE=`basename $FILE`
GENELISTS=$2/*_genes
if [ "$3" != "" ] ; then
  EMAIL=$3
else
  EMAIL='Not Supplied'
fi

#check suffix
FILE_SFX=`echo $FILE | rev | cut -d '.' -f1 | rev `
#check mime-type
MIME=`file --mime-type $FILE | awk '{print $2}'`

#Create names for working directory and working files.
TEMP_DIR=${FILE}.dir
mkdir $TEMP_DIR
cd $TEMP_DIR
ln ../$FILE .
RES=$FILE.res
REPORT=$FILE.rep
#File size
FILESIZE=`du -sh $FILE | cut -f1`

#File checksum
FILECHECKSUM=`md5sum $FILE | awk '{print $1}'`

#Check the filename in case its a ZIP archive
ssconvert -S --export-type Gnumeric_stf:stf_assistant -O 'separator="'$'\t''" ' \
$FILE $FILE.txt #2> /dev/null

#count the columns in each sheet
for SHEET in $FILE.txt* ; do
  TMP=$SHEET.tmp
  NF=`head $SHEET | awk '{print NF}' | numaverage -M`

  #intersect top 20 fields from each column of data with a list of gene names
  for COL in `seq $NF` ; do
    cut -f$COL $SHEET | head -20 > $TMP

    #Guess which species - this is not 100% correct as search as only 20
    #fields are scanned
    SPEC=`grep -cxFf $TMP $GENELISTS | awk -F: '$2>4' | sort -t\: -k2gr \
    | head -1 | cut -d ':' -f1 | tr '/' ' ' | awk '{print $NF}' \
    | cut -d '_' -f1`

    #If >4 of the top 20 cells are recognised as genes, then regex with awk
    if [ -n "$SPEC" ] ; then
      echo $SHEET col:$COL species:$SPEC >> $RES
      #Run the regen screen on the column
      cut -f$COL $SHEET | sed '1,2d' \
      | awk ' /[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9]/ || /[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ || (/[0-9]\-(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/) || /[0-9]\.[0-9][0-9]E\+[0-9][0-9]/ ' \
      | sed "s#^#${DATE}\t${DOI}\t${SHEET}\t${COL}\t#" >> $RES
    fi
  done
done

rm *tmp

#Record some infor to include in the report
DATE=`date -u`

NUMSHEETS=`find . | grep -c "$FILE.txt"`

GENELIST=`grep -c species $RES`

ERRORS=`grep -c ^201 $RES`

if [ $ERRORS -gt 0 ] ; then
  ERRORMESSAGE="!!!The scanning software has identified a gene name error!!! There are many ways to avoid this. Visit http://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-5-80 to learn more about preventing gene name errors when using Excel."
else
  ERRORMESSAGE="The scanning software has not identified any gene name errors :)"
fi

#Write out the report
cat <<EOT | fold -s -w120 | sed 's/$/<br>/' > ../$REPORT
######################################################################
Gene Name Error Scanner Report - By Mark Ziemann - Twitter: @mdziemann
Current version: $VERSION
######################################################################

Date: $DATE
Email: $EMAIL
File name: $FILE
File type: $MIME
File size: $FILESIZE
File MD5 checksum: $FILECHECKSUM
Number of sheets: $NUMSHEETS
Gene lists found: $GENELIST
Gene name errors found: $ERRORS

$ERRORMESSAGE
EOT

SHEETNUM=1
for SHEET in $FILE.txt* ; do

  GLIST=`grep $SHEET $RES | grep -c species`

cat <<EOT | sed 's/$/<br>/' >> ../$REPORT

Sheet $SHEETNUM no. genelists: $GLIST
EOT

  if [ "$GLIST" -gt "0" ] ; then

    GSPECIES=`grep -w $SHEET $RES | grep species | awk '{print $3}' | cut -d ':' -f2 | tr '\n' ',' | sed 's/,$/\n/'`

    GCOL=`grep -w $SHEET $RES | grep species | awk '{print $2}' | cut -d ':' -f2 | tr '\n' ',' | sed 's/.$/\n/'`

    GNUMERRORS=`grep ^2 $RES | grep -wc $SHEET `

    GERRORS=`grep ^2 $RES | grep -w $SHEET | awk '{print $4}' | tr '\n' ',' | sed 's/.$/\n/'`


    if [ "$GERRORS" == "" ] ; then
      GERRORS='None identified'
    fi


cat <<EOT | sed 's/$/<br>/' >> ../$REPORT
Sheet $SHEETNUM gene list species: $GSPECIES
Sheet $SHEETNUM gene list column: $GCOL
Sheet $SHEETNUM no. gene name errors: $GNUMERRORS
Sheet $SHEETNUM gene name errors: $GERRORS
EOT
  fi
  let SHEETNUM+=1
done

rm *res
cd ..


cat <<EOT | fold -s -w120 | sed 's/$/<br>/' >> $REPORT

Notes: Thanks for using Gene Name Error Scanner. We provide this free tool to the genomics community \
to help in the identification of spreadsheet gene name errors. Please understand that this tool is \
designed to catch the most common types of gene name errors. It can only recognise gene names from the \
most commonly used model organisms. Your milage may vary with less well-characterised organisms. \
This tool only identifies vertical gene lists that occur in the top 20 lines of a spreadsheet. \
Horizontal gene lists and gene names in random places will most likely not be correctly identified. \
I'm very happy to hear any feedback you may have via twitter, my alias is "@mdziemann".

Disclaimer: Although all reasonable efforts have been taken to ensure the accuracy and reliability of the \
data and underlying software, the author and author's employer do not and cannot warrant the \
performance or results that may be obtained by using this software or data. We disclaim all warranties, \
express or implied, including warranties of performance, merchantability or fitness for any particular \
purpose.

EOT

#dump to screen
cat $REPORT

sed -i 's/<br>//g' $REPORT
enscript -B --margins=10:10: -o $REPORT.ps -f Courier@7.3/10 $REPORT
ps2pdfwr $REPORT.ps $FILE.pdf

cat <<EOT
<form action="code/$FILE.pdf">
    <input type="submit" value="Download PDF" />
</form>
<button onclick="goBack()">Go Back</button>

<script>
function goBack() {
    window.history.back();
}
</script>
EOT



if [ "$EMAIL" != "" ] ; then
  cat <<EOT > $FILE.msg
Dear Madam or Sir,
This is an automatically generated mail from the Gene Name Errors Scan webservice. In the attached \
PDF file, you can view the Gene Name Error Scanner Report for the file $FILE which was submitted on \
$DATE. If you have feedback regarding this service, received this email in error or do not want to \
receive emails in future, contact Mark Ziemann (mark.ziemann@gmail.com) the maintainer of this \
webservice.
Kind regards,
Mark
EOT

  mail -s "Gene Name Error Scan Report" ${EMAIL} -A $FILE.pdf < $FILE.msg
fi

#delete the working directory
rm $1
rm -rf $TEMP_DIR
rm $FILE $REPORT.ps $FILE.rep $FILE.msg
#sleep 1h ; rm $FILE.pdf 
}

export -f scanit

#Now run the function in parallel
scanit $1 $GENELIST_DIR $2
