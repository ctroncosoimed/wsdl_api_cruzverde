namespace :create_document do
  desc "Se crean documento en dec para ser ocupados posteriormente por un proceso"
  task :create_on_dec, [:code_file] => [:environment] do |t, args|

    @range= 500 #Cuantos Documentos se van a crear
    @codigo_dec = [] #Array que contendra los codigos dec
    @usuario= 'Autentia'
    @clave= '@ut3nti4.'
    @code= args[:code_file]

    def at 
      busy= TableService.where(busy: false).count(:busy)
      total= @range-busy
      total
    end

    unless at == 0
      (1..at).each do |i| 
        request= Typhoeus.post("https://docscap.dec.cl/cgi-bin/autentia-docs4.cgi",
          body:"
            <soapenv:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:urn='urn:wsdocs4'>
             <soapenv:Header/>
             <soapenv:Body>
                <urn:wsAddDoc soapenv:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>
                   <ReqAdd xsi:type='urn:CAddDocsReq'>
                      <wsUsuario xsi:type='xsd:string'>#{@usuario}</wsUsuario>
                      <wsClave xsi:type='xsd:string'>#{@clave}</wsClave>
                      <Doc xsi:type='urn:CDocBas'>
                         <CodPais xsi:type='xsd:string'>CL</CodPais>
                         <Institucion xsi:type='xsd:string'>CRUZVERDE</Institucion>
                         <CodTipo xsi:type='xsd:string'>#{@code}</CodTipo>
                         <NomArchivo xsi:type='xsd:string'>Voucher</NomArchivo>
                         <CodPaisCreador xsi:type='xsd:string'>CL</CodPaisCreador>
                         <RutCreador xsi:type='xsd:string'>17615747-K</RutCreador>
                         <RolCreador xsi:type='xsd:string'>AUDITORCV</RolCreador>
                      </Doc>
                      <Info xsi:type='urn:CDocInfo'>
                         <CodigoDoc xsi:type='xsd:string'/>
                         <Descrip xsi:type='xsd:string'></Descrip>
                         <Metadata xsi:type='xsd:string'/>
                         <MetaTag xsi:type='xsd:string'/>
                         <MimeType xsi:type='xsd:string'></MimeType>
                         <CodLugar xsi:type='xsd:string'></CodLugar>
                         <Estado>0</Estado>
                         <Tamano xsi:type='xsd:long'/>
                         <Archivo xsi:type='xsd:base64Binary'>YQ==</Archivo>
                         <md5 xsi:type='xsd:string'/>
                         <FecModific xsi:type='xsd:string'/>
                         <NomEmpresa xsi:type='xsd:string'></NomEmpresa>
                         <RutHolding xsi:type='xsd:string'/>
                         <RutEmpresa xsi:type='xsd:string'/>
                         <UrlVerif xsi:type='xsd:string'>1</UrlVerif>
                         <xslVista xsi:type='xsd:base64Binary'/>
                         <Reserved>0</Reserved>
                         <LastY>0</LastY>
                         <nFirmados>0</nFirmados>
                      </Info>
                      <bCodUrl>false</bCodUrl>
                   </ReqAdd>
                </urn:wsAddDoc>
             </soapenv:Body>
            </soapenv:Envelope>
          ",
          headers:{Accept: "application/xml"}
        )
        result= Hash.from_xml(request.body)

        if result["Envelope"]["Body"]["CDocsResp"]["Resultado"]["Err"].to_i == 0
          @codigo_dec << result["Envelope"]["Body"]["CDocsResp"]["CodigoDoc"]
        else
          puts result["Envelope"]["Body"]["CDocsResp"]["Resultado"]["Glosa"]  
        end
      end

      @codigo_dec.each do |insert|
        insert_on_table= TableService.new(dec_code: insert,id_code: args[:code_file], busy: false)
        if insert_on_table.save
           puts "Documento: #{insert} Creado"
        else
          puts "Problemas al guardar #{insert}"
        end
      end
      puts "Total Creados #{@codigo_dec.size}"
    else
      puts "Se Encuentran el limite de archivos vacio"
    end
  end
end