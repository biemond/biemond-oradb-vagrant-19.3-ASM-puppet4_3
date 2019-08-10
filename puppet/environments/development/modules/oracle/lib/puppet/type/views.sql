
select control.name as from v$controlfile control;

select TYPE,RECORDS_TOTAL from v$controlfile_record_section;