module Evergreen.V337.Authentication exposing (..)

import Dict
import Evergreen.V337.Credentials
import Evergreen.V337.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V337.User.User
    , credentials : Evergreen.V337.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
