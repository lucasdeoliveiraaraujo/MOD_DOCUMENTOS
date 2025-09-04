CREATE OR REPLACE package mod_documentos IS
    function obterDocumento(idDoc number, filtro varchar2) return varchar2;
    
    function executaBusca(query varchar2, filtro varchar2) return varchar2;
    
    function montarDocumento(documento clob, dados varchar2) return clob;
end mod_documentos;
/


CREATE OR REPLACE package body mod_documentos IS
    
    function obterDocumento(idDoc number, filtro varchar2) return varchar2 is
    --cursores
    cursor cDocumento(idDoc number)is
        select doc.documento, doc.query
        from documentos doc
        where id = idDoc;
          
    --variaveis          
    vDocumento clob;
    vDocumentoModelo clob;
    vQuery varchar2(4000);
    vJson varchar2(4000);
    vJsonArray Json_Array_t := Json_Array_t();
    begin
        open cDocumento(idDoc => idDoc);
        fetch cDocumento into vDocumentoModelo, vQuery;
        if(cDocumento%found and vQuery is not null)then
             vJson := executaBusca(query => vQuery, filtro => filtro);
             if (instr(vJson, '[') > 0) then
                vJsonArray := Json_Array_t(vJson);
                for i in 0..vJsonArray.get_size() - 1 loop
                    vDocumento := vDocumento||montarDocumento(documento => vDocumentoModelo, dados =>vJsonArray.get(i).to_string());
                end loop;
             else
                vDocumento := montarDocumento(documento => vDocumentoModelo, dados =>vJson);
             end if;
             
        end if;
        close cDocumento;
        
        return vDocumento;
    exception 
        when others then
            close cDocumento;
            raise_application_error(-20000, sqlerrm||chr(10)||dbms_utility.format_error_backtrace);
    end obterDocumento;
    
    function executaBusca(query varchar2, filtro varchar2) return varchar2 is
    --variaveis
    wJson varchar2(4000);
    
    begin
        execute immediate '
            
        begin
            
            execute immediate :query into :wJson using '||filtro||' ;

        end;' using in ''||query||'', out wJson ;
        
        return wJson;
    end executaBusca;
    
    function montarDocumento(documento clob, dados varchar2) return clob is
        vDocumento clob := documento;
    begin
        execute immediate '
        declare
            wJson json_object_t := json_object_t();
        begin
            wJson := json_object_t.parse(:dados);
            :vDocumento := '''||vDocumento||''';

        end;' using in ''||dados||'', out vDocumento ;
        
        return vDocumento;
    end montarDocumento;
end mod_documentos;
/
