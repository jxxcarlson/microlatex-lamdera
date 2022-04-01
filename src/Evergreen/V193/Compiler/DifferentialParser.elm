module Evergreen.V193.Compiler.DifferentialParser exposing (..)

import Evergreen.V193.Compiler.AbstractDifferentialParser
import Evergreen.V193.Compiler.Acc
import Evergreen.V193.Parser.Block
import Evergreen.V193.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V193.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V193.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V193.Parser.Block.ExpressionBlock) Evergreen.V193.Compiler.Acc.Accumulator
