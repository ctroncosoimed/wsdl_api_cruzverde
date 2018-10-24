namespace :upload_document do
  desc "Carga los documentos al DEC5"
  task upload: :environment do
    
    require "base64"

    i = 0
    @firmantes= []
    @tags= []

    loop do
      response= TableService.where(busy: true).first
      break if response == nil

      unless response.signatories.nil?
        response.signatories.map do |x| #Firmantes
          @firmantes << "<Firmas xsi:type='urn:CFirmante'>
                          <Rol xsi:type='xsd:string'>#{x["ROL"]}</Rol>
                          <CodPaisRut xsi:type='xsd:string'>CL</CodPaisRut>
                          <Rut xsi:type='xsd:string'>#{x["Rut"]}</Rut>
                          <NroAudit xsi:type='xsd:string'>#{x["Auditoria"]}</NroAudit>
                          <FecFirma xsi:type='xsd:string'></FecFirma>
                          <email xsi:type='xsd:string'>mgarcia@i-med.cl</email>
                          <Descrip xsi:type='xsd:string'></Descrip>
                          <FlagsMail>0</FlagsMail>
                          <EstadoMail>-1</EstadoMail>
                          <EstadoFirma>#{x["TipoFirma"].to_i == 5  ? 4 : 0}</EstadoFirma>
                          <TipoFirma>#{x["TipoFirma"].to_i}</TipoFirma>
                          <Institucion xsi:type='xsd:string'>#{x["Intitucion"]}</Institucion>
                          <CodLugar xsi:type='xsd:string'></CodLugar>
                          <Orden>1</Orden>
                          <PatronFirma>0</PatronFirma>
                          <outHabilitado>#{x["TipoFirma"].to_i == 5  ? 1 : 0}</outHabilitado>
                          <FecDesde xsi:type='xsd:string'></FecDesde>
                          <FecHasta xsi:type='xsd:string'></FecHasta>
                          <Accion>1</Accion>
                        </Firmas>"
        end
      end

      unless response.tags.nil? #tags
        response.tags.each do |key, value|
          key.each do |keys, values|
            if keys.present? and values.present?
              @tags << "<Tags xsi:type='urn:CTag'>
                          <CodTag xsi:type='xsd:string'>#{keys unless keys.nil?}</CodTag>
                          <Valor xsi:type='xsd:string'>#{values unless values.nil?}</Valor>
                          <outDescrip xsi:type='xsd:string'></outDescrip>
                        </Tags>"
            end
          end
        end
      end

      request= Typhoeus.post("https://docscap.dec.cl/cgi-bin/autentia-docs4.cgi", body: "
      <soapenv:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:urn='urn:wsdocs4'>
        <soapenv:Header/>
        <soapenv:Body>
          <urn:wsUpdateDoc soapenv:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>
             <ReqUpd xsi:type='urn:CUpdDocReq'>
              <wsUsuario xsi:type='xsd:string'>Autentia</wsUsuario>
              <wsClave xsi:type='xsd:string'>@ut3nti4.</wsClave>
              <Institucion xsi:type='xsd:string'>#{response.institution unless response.institution.nil?}</Institucion>
              <CodTipo xsi:type='xsd:string'>#{response.id_code unless response.id_code.nil?}</CodTipo>
              <Info xsi:type='urn:CDocInfo'>
                 <CodigoDoc xsi:type='xsd:string'>#{ response.dec_code unless response.dec_code.nil? }</CodigoDoc>
                 <Descrip xsi:type='xsd:string'>#{ response.description unless response.description.nil? }</Descrip>
                 <Metadata xsi:type='xsd:string'></Metadata>
                 <MetaTag xsi:type='xsd:string'></MetaTag>
                 <MimeType xsi:type='xsd:string'>application/#{response.file_mime unless response.file_mime.nil?}</MimeType>
                 <CodLugar xsi:type='xsd:string'>CL</CodLugar>
                 <Estado>0</Estado>
                 <Tamano> #{Base64.decode64(response.file).size unless response.file.nil?} </Tamano>
                 <Archivo xsi:type='xsd:base64Binary'>#{response.file unless response.file.nil?}</Archivo>
                 <md5 xsi:type='xsd:string'></md5>
                 <MimeThumb xsi:type='xsd:string'></MimeThumb>
                 <Thumbnail xsi:type='xsd:base64Binary'></Thumbnail>
                 <FecModific xsi:type='xsd:string'></FecModific>
                 <NomEmpresa xsi:type='xsd:string'></NomEmpresa>
                 <RutHolding xsi:type='xsd:string'></RutHolding>
                 <RutEmpresa xsi:type='xsd:string'></RutEmpresa>
                 <UrlVerif xsi:type='xsd:string'></UrlVerif>
                 <xslVista xsi:type='xsd:base64Binary'></xslVista>
                 <Reserved>0</Reserved>
                 <LastY>0</LastY>
                 <nFirmados>0</nFirmados>
                #{@firmantes.join}
                #{@tags.join}
              </Info>
              <Interno>0</Interno>
              <CodSesion xsi:type='xsd:string'></CodSesion>
            </ReqUpd>
          </urn:wsUpdateDoc>
        </soapenv:Body>
      </soapenv:Envelope>",
      headers:{ Accept: "application/xml" }
      )

      unless response.related_document.nil?
        request_related= Typhoeus.post("https://docscap.dec.cl/cgi-bin/autentia-docs4.cgi", body: "
          <soapenv:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:urn='urn:wsdocs4'>
             <soapenv:Header/>
             <soapenv:Body>
                <urn:wsAddRelac soapenv:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>
                   <ReqAddRelac xsi:type='urn:CRelacReq'>
                      <wsUsuario xsi:type='xsd:string'>Autentia</wsUsuario>
                      <wsClave xsi:type='xsd:string'>@ut3nti4.</wsClave>
                      <CodigoDoc xsi:type='xsd:string'>#{response.related_document}</CodigoDoc>
                      <CodPais xsi:type='xsd:string'>CL</CodPais>
                      <Institucion xsi:type='xsd:string'>#{response.institution}</Institucion>
                      <Relac xsi:type='urn:CRelacion'>
                         <CodigoRel xsi:type='xsd:string'>#{response.dec_code}</CodigoRel>
                         <Fecha xsi:type='xsd:string'></Fecha>
                      </Relac>
                      <!--Optional:-->
                      <CodSesion xsi:type='xsd:string'>?</CodSesion>
                   </ReqAddRelac>
                </urn:wsAddRelac>
             </soapenv:Body>
          </soapenv:Envelope>
        ",
        headers:{ Accept: "application/xml" })
      end

      result= Hash.from_xml(request.body)

      unless response.related_document.nil?
        result_related= Hash.from_xml(request_related.body) 
        puts result_related
      end

      puts "#{response.dec_code} Guardado" if result["Envelope"]["Body"]["CDocsResp"]["Resultado"]["Err"].to_i == 0
      if (result["Envelope"]["Body"]["CDocsResp"]["Resultado"]["Err"].to_i == 5201) or (result["Envelope"]["Body"]["CDocsResp"]["Resultado"]["Err"].to_i == 0)
        response.destroy
        puts "#{response.dec_code} Borrado"
      end
    end

    puts '-----------------------------------'
    puts "No quedan documentos por guardar"
    puts '-----------------------------------'
  end
end