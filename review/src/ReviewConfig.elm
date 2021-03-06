module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import CognitiveComplexity
import NoExposingEverything
import NoImportingEverything
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Dependencies.rule
    , NoImportingEverything.rule [ "Element" ]
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , NoExposingEverything.rule

    --, CognitiveComplexity.rule 25
    ]
        |> List.map
            (Review.Rule.ignoreErrorsForFiles
                [ "src/Types.elm"
                , "src/Env.elm"
                , "src/CollaborativeEditing/NetworkSimulator2.elm"
                , "src/CollaborativeEditing/NetworkSimulator3.elm"
                , "vendor/jinjor/elm-debounce/3.0.0/src/Debounce.elm"
                , "compiler/Tools.elm"
                , "compiler/Render/Chart.elm"
                , "compiler/Render/Block.elm"
                , "compiler/Parser/Tools.elm"
                , "compiler/Compiler/Acc.elm"
                ]
            )
