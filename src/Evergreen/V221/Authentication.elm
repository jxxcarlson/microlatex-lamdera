module Evergreen.V221.Authentication exposing (..)

import Dict
import Evergreen.V221.Credentials
import Evergreen.V221.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V221.User.User
    , credentials : Evergreen.V221.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
