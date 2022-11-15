#! /bin/bash
# ------------------------------------------------------------------
# house keeping script to update bapp files
# ------------------------------------------------------------------
VERSION=0.0.1

echo -e "this is not functioning yet.\n"
exit 1


	cat >example.bapp <<EOF
BAPP=1.0
ID=EXMPL
Name=template
Comment='purpose long'
Ver=0.0
localVer=0.0
W3='http://appweb.page'

INSTALL(){
    echo "###################################"
    echo "#	Installing $ID 	"
    echo "###################################"

}

REMOVE(){
    echo "###################################"
    echo "#	Removing $ID 	"
    echo "###################################"
    echo -e "\n this function is not ready"
}

VERSION(){
    NEWVER=0.0
    CURRENT=0.0
}

MENU(){
    echo "a place to set the menu config"
}


EOF

