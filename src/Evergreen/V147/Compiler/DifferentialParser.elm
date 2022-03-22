module Evergreen.V147.Compiler.DifferentialParser exposing (..)

import Evergreen.V147.Compiler.AbstractDifferentialParser
import Evergreen.V147.Compiler.Acc
import Evergreen.V147.Parser.Block
import Evergreen.V147.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V147.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V147.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V147.Parser.Block.ExpressionBlock) Evergreen.V147.Compiler.Acc.Accumulator
