module Evergreen.V152.Authentication exposing (..)

import Dict
import Evergreen.V152.Credentials
import Evergreen.V152.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V152.User.User
    , credentials : Evergreen.V152.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
