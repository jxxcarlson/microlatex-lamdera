module Evergreen.V268.Authentication exposing (..)

import Dict
import Evergreen.V268.Credentials
import Evergreen.V268.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V268.User.User
    , credentials : Evergreen.V268.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
