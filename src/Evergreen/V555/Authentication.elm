module Evergreen.V555.Authentication exposing (..)

import Dict
import Evergreen.V555.Credentials
import Evergreen.V555.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V555.User.User
    , credentials : Evergreen.V555.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
