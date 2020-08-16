sqlplus "sys/sa@CARTERS as sysdba" @"C:\Users\Brendon\Documents\GitHub\Load_DB\Win64\Debug\cr_axiom_user.sql"
imp axiom/as@CARTERS parfile=import.txt
exit
