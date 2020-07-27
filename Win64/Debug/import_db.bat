sqlplus "sys/axiom@BLACKER as sysdba" @"D:\Insight_XE4_Source\DB_Load\Win64\Debug\cr_axiom_user.sql"
imp axiom/axiom@BLACKER parfile=import.txt
exit
