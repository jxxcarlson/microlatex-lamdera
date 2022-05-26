module Evergreen.V526.Authentication exposing (..)

import Dict
import Evergreen.V526.Credentials
import Evergreen.V526.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V526.User.User
    , credentials : Evergreen.V526.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
