module Evergreen.V453.Authentication exposing (..)

import Dict
import Evergreen.V453.Credentials
import Evergreen.V453.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V453.User.User
    , credentials : Evergreen.V453.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
