module Evergreen.V718.Authentication exposing (..)

import Dict
import Evergreen.V718.Credentials
import Evergreen.V718.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V718.User.User
    , credentials : Evergreen.V718.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
