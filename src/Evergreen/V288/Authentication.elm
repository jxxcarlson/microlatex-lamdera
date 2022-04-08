module Evergreen.V288.Authentication exposing (..)

import Dict
import Evergreen.V288.Credentials
import Evergreen.V288.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V288.User.User
    , credentials : Evergreen.V288.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
