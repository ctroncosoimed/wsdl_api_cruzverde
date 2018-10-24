class ApplicationController < ActionController::API
  require "base64"
  require 'open-uri'

  def token_validate
    return render json: {CodError:1, mensaje: "Token Invalido", status: 400} unless User.find_by(token: params[:auth_token])
  end

  def audit_validate
    if params[:accion].downcase == 'firma'
      @auditoria = []
      @rut = []
      params[:Firmantes].map do |x| 
        if x["Auditoria"].present?
          @auditoria << x["Auditoria"]
          @rut << x["Rut"]
        end
      end
      return render json: {CodError:1, mensaje: "Debe haber almenos 1 auditoria", status: 400} unless @auditoria.present?
      
      request=
        Typhoeus.post("http://200.0.156.150/cgi-bin/autentia-audit.cgi",
          body:"
            <soapenv:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:urn='urn:wsaudit'>
               <soapenv:Header/>
               <soapenv:Body>
                  <urn:wsaudit soapenv:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>
                     <WSAuditReadReq xsi:type='urn:CAuditReadReq'>
                        <wsUsuario xsi:type='xsd:string'>Autentia</wsUsuario>
                        <wsClave xsi:type='xsd:string'>@ut3nti4.</wsClave>
                        <NroAudit xsi:type='xsd:string'>#{@auditoria.join}</NroAudit>
                        <bWsq>true</bWsq>
                        <bBmp>false</bBmp>
                     </WSAuditReadReq>
                  </urn:wsaudit>
               </soapenv:Body>
            </soapenv:Envelope>
          ",
          headers:{Accept: "application/xml"})


      result= Hash.from_xml(request.body)
      return render json: {CodError:1, mensaje: "#{result["Envelope"]["Body"]["WSAuditReadResp"]["Resultado"]["Glosa"]}", status: 400} if result["Envelope"]["Body"]["WSAuditReadResp"]["Resultado"]["Err"].to_i == 5000
      return render json: {CodError:1, mensaje: "Auditoria NO valida para CRUZVERDE", status: 400} if result["Envelope"]["Body"]["WSAuditReadResp"]["DatosSistema"]["Institucion"] != 'CRUZVERDE' 
      return render json: {CodError:1, mensaje: "Rut no es Valido para la Auditoria", status: 400} if result["Envelope"]["Body"]["WSAuditReadResp"]["DatosAuditados"]["Rut"] != @rut.join
    
    end
  end


  def params_validate
    return render json: { CodError:1, mensaje: "Institución es obligatoria", status: 400 } unless params[:Institucion].present?

    return render json: { CodError:1, mensaje: "TipoDoc es obligatorio", status: 400 } unless params[:TipoDoc].present?
    return render json: { CodError:1, mensaje: "TipoDoc es invalido", status: 400 }  unless params[:TipoDoc] !~ /[^a-z0-9]/i

    return render json: { CodError:1, mensaje: "DescripcionDocumento es obligatorio", status: 400 } unless params[:DescripcionDocumento].present?

    return render json: { CodError:1, mensaje: "File_mime es obligatorio", status: 400 } unless params[:File_mime].present?
    return render json: { CodError:1, mensaje: "File_mime no permitido", status: 400 } unless /txt|pdf|xml/.match(params[:File_mime].downcase)

    return render json: { CodError:1, mensaje: "File es obligatorio", status: 400 } unless params[:File].present?
    return render json: { CodError:1, mensaje: "File no corresponse a un archivo en base64", status: 400 } if (validate_base64 = params[:File].match /^(?:[A-Za-z0-9+\/]{4}\n?)*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/).nil?    

    return render json: { CodError:1, mensaje: "Acción es obligatorio", status: 400 } unless params[:accion].present?
    return render json: { CodError:1, mensaje: "Acción no valida", status: 400 } unless /firma|digitalizacion/.match(params[:accion].downcase)

    return render json: { CodError:1, mensaje: "Firmantes es obligatorio", status: 400 } unless params[:Firmantes].present?

    empty_data = []
    key_data = []
    row = 0

    params[:Firmantes].map do |x|
      row += 1
      empty_data << x.empty?
      key_data << " #{row}º Array parametro ROL " unless x.keys.include?("ROL")
      key_data << " #{row}º Array parametro EmailFirmante " unless x.keys.include?("EmailFirmante")
      key_data << " #{row}º Array parametro Rut " unless x.keys.include?("Rut")
      key_data << " #{row}º Array parametro NombreCompleto " unless x.keys.include?("NombreCompleto")
      key_data << " #{row}º Array parametro TipoFirma " unless x.keys.include?("TipoFirma")
      key_data << " #{row}º Array parametro Auditoria " unless x.keys.include?("Auditoria")
      
      if x["Auditoria"].present? and params[:accion].downcase == 'firma'
        @validate_rut = RUT::validate(RUT::format(x['Rut'])) ? true : false
        @validate_rol = x["ROL"] == "(Personal)" ? true : false
        @validate_tipo_firma = x["TipoFirma"].to_i == 0 ? true : false

      elsif params[:accion].downcase == 'firma'
        @validate_rut = RUT::validate(RUT::format(x['Rut'])) ? true : false
        @validate_tipo_firma_nf = x["TipoFirma"].to_i == 5 ? true : false #nf No Firmante

      elsif params[:accion].downcase == 'digitalizacion'
        @validate_audit_digitalizacion = "La digitalización no puede llevar auditoria" if x['Auditoria'].present?
        @validate_tipo_firma_digitalizacion = "La digitalización debe ir con TipoFirma 5" if x['TipoFirma'].to_i != 5
      
      end
    end

    #validaciones para los firmantes
    return render json: { CodError:1, mensaje: "Firmantes no puede estar vacio", status: 400 } if empty_data.include?(true)
    return render json: { CodError:1, mensaje: "El #{key_data.join} no esta incluido ", status: 400 } unless key_data.empty?
    return render json: { CodError:1, mensaje: "El Rut no es valido", status: 400 } if @validate_rut == false
    return render json: { CodError:1, mensaje: "El ROL es distinto de (Personal) 'Debe ser (Personal) solo aplica para los roles con auditoria' ", status: 400 } if @validate_rol == false
    return render json: { CodError:1, mensaje: "El TipoFirma es distinto de 0 'Debe ser 0, solo aplica para los roles con auditoria' FIRMA: #{params[:TipoFirma].to_i}", status: 400 } if @validate_tipo_firma == false
    return render json: { CodError:1, mensaje: "El TipoFirma es distinto de 5 'Debe ser 5, solo aplica para los roles sin auditoria' ", status: 400 } if @validate_tipo_firma_nf == false
    return render json: { CodError:1, mensaje: "#{@validate_audit_digitalizacion}", status: 400 } if @validate_audit_digitalizacion.present?
    return render json: { CodError:1, mensaje: "#{@validate_tipo_firma_digitalizacion}", status: 400 } if @validate_tipo_firma_digitalizacion.present?
  end


  def error404
    return render json: { CodError:1, mensaje: "ruta no encontrada", status: 404 }
  end

end