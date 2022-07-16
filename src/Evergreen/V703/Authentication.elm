module Evergreen.V703.Authentication exposing (..)

import Dict
import Evergreen.V703.Credentials
import Evergreen.V703.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V703.User.User
    , credentials : Evergreen.V703.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
