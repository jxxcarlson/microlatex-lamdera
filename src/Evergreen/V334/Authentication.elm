module Evergreen.V334.Authentication exposing (..)

import Dict
import Evergreen.V334.Credentials
import Evergreen.V334.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V334.User.User
    , credentials : Evergreen.V334.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
