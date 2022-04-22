module Evergreen.V447.Authentication exposing (..)

import Dict
import Evergreen.V447.Credentials
import Evergreen.V447.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V447.User.User
    , credentials : Evergreen.V447.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
