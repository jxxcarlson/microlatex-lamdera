module Evergreen.V359.Authentication exposing (..)

import Dict
import Evergreen.V359.Credentials
import Evergreen.V359.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V359.User.User
    , credentials : Evergreen.V359.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
