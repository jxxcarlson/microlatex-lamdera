module Evergreen.V314.Authentication exposing (..)

import Dict
import Evergreen.V314.Credentials
import Evergreen.V314.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V314.User.User
    , credentials : Evergreen.V314.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
