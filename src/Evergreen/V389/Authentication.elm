module Evergreen.V389.Authentication exposing (..)

import Dict
import Evergreen.V389.Credentials
import Evergreen.V389.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V389.User.User
    , credentials : Evergreen.V389.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
