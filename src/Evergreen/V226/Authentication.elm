module Evergreen.V226.Authentication exposing (..)

import Dict
import Evergreen.V226.Credentials
import Evergreen.V226.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V226.User.User
    , credentials : Evergreen.V226.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
