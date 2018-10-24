class V1::FirmaElectronicaController < ApplicationController
  before_action :token_validate
  before_action :audit_validate
  before_action :params_validate

  def index
    @result = save_document
    render json: @result
  end

  def save_document
    document = TableService.where(busy: false, id_code: params[:TipoDoc]).first
    if document.present?
      params[:File] = to_pdf_base64
      params[:File_mime] = 'pdf'
      if params[:accion].downcase == 'firma'
        update = document.update_attributes(institution: params[:Institucion],
                                            description: params[:DescripcionDocumento],
                                            file_mime: params[:File_mime],
                                            file: params[:File],
                                            signatories: params[:Firmantes],
                                            tags: params[:Tags],
                                            busy: true,
                                            id_action: 1,
                                            type_action: 'firma')

        codigo_dec = document.dec_code
        result = update ? true : false

      elsif params[:accion].downcase == 'digitalizacion'

        update = document.update_attributes(institution: params[:Institucion],
                                            description: params[:DescripcionDocumento],
                                            file_mime: params[:File_mime],
                                            file: params[:File],
                                            signatories: params[:Firmantes],
                                            tags: params[:Tags],
                                            related_document: params[:DocRelacionados],
                                            busy: true,
                                            id_action: 1,
                                            type_action: 'digitalizacion')

        codigo_dec = document.dec_code
        result = update ? true : false
      end
      response = create_response(params, result, codigo_dec)
    else
      response = { CodError:1, mensaje:'No se pudo guardar el documento, No quedan documentos reservados', status:400 }
    end
    
    response
  end

  def create_response(params, result, codigo_dec)

    if result == true 
      if params[:accion].downcase == 'firma'
        @firmantes= []
        @auditoria= []
        params[:Firmantes].map do |x|
          if x["Auditoria"].present?
            @firmantes << x["Rut"]
            @auditoria << x["Auditoria"]
          end
        end
        response = { CodError: 0,
                     Mensaje: "OK",
                     CodigoDEC: "#{ codigo_dec }",
                     LadrilloDeFirma: "Este documento es una representación de un documento original en formato electrónico. Para verificar el estado actual del documento verificarlo en 5cap.dec.cl Firmante: #{@firmantes.join}, Institución: #{params[:Institucion]}, Fecha de Firma: #{DateTime.now.strftime("%d/%m/%Y")}, Auditoria: #{@auditoria.join}, Operador: 1-9",
                     status: 201 }


      elsif params[:accion].downcase == 'digitalizacion'
        response = { CodError: 0,
                    Mensaje: 0,
                    CodigoDEC: "#{ codigo_dec }" }
      end
    elsif result == false
      response = { CodError:1, mensaje:'No se pudo guardar el documento', status:400 } 
    end
    response
  end

  def to_pdf_base64

    if params[:File_mime].downcase == 'txt'
      plain = Base64.decode64(params[:File])
      pdf_text = WickedPdf.new.pdf_from_string("<pre>#{plain}</pre>", encoding: 'utf-8')
      
    elsif params[:File_mime].downcase == 'xml'
      hash = Hash.from_xml(params[:File].gsub("\n", ""))
      plain = Base64.decode64(params[:File])
      pdf_text = WickedPdf.new.pdf_from_string("<pre>#{hash['documento']['head']}</pre> 
                                                </br>
                                                <pre>#{hash['documento']['body']}</pre>
                                                </br>
                                                <pre>#{hash['documento']['footer']}</pre>", encoding: 'utf-8')
    end
    @pdf_base64 = Base64.encode64(pdf_text)

    @pdf_base64
  end

end