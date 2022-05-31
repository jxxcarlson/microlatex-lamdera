module Evergreen.V537.Authentication exposing (..)

import Dict
import Evergreen.V537.Credentials
import Evergreen.V537.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V537.User.User
    , credentials : Evergreen.V537.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
