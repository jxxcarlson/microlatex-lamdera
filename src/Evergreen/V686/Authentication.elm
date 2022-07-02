module Evergreen.V686.Authentication exposing (..)

import Dict
import Evergreen.V686.Credentials
import Evergreen.V686.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V686.User.User
    , credentials : Evergreen.V686.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
