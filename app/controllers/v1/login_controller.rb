class V1::LoginController < ApplicationController

  def index
    render json: user_validate
  end

  def user_validate
    return render json: { mensaje: "Debe ingresar usuario o contraseña", status: 400 } unless params[:user].present? and params[:password].present?

    if @usuario = User.find_by(user: params[:user])
      response =
        if BCrypt::Password.new( @usuario['password_digest'] ) == params[:password]
          { CodError: 0, message: "#{ @usuario['token'] }", status: 200 }
        else
          { CodError: 1, mensaje: "Usuario o Contraseña Invalido", status: 400 }
        end
    else
      response = { CodError: 1, mensaje: "Usuario o Contraseña Invalido", status: 400 }
    end
    response
  end

end