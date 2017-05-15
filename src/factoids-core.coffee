# Description:
#   Provides important functions used by the main Factoids code.

natural = require 'natural'

class Factoids
    constructor: (@robot) ->
        if @robot.brain?.data?
            @data = @robot.brain.data.factoids ?= {}

        @robot.brain.on 'loaded', ->
        @data = @robot.brain.data.factoids ?= {}

    set: (key, value, who, resolveAlias) ->
        key = key.trim()
        value = value.trim()
        fact = @get key, resolveAlias

        if typeof fact is 'object'
            fact.history ?= []
            hist =
                date: Date()
                editor: who
                oldValue: fact.value
                newValue: value

            fact.history.push hist
            fact.value = value
            if fact.forgotten? then fact.forgotten = false
        else
            fact =
                value: value
                popularity: 0

        @data[tokenizeAndStem(key)] = fact

    get: (key, resolveAlias = true) ->
        key = key.toLowerCase()
        fact = @data[key] #check for exact match
        alias = fact?.value?.match /^@([^@].+)$/i
        if not fact 
            tokStemmedKey = tokenizeAndStem(key)
            fact = @data[tokStemmedKey] 
            #check for tokenized and stemmed match
            if not fact and 1 < tokStemmedKey.length <= 3 
            #if still not found, then do a bigram and trigram comparison
                arrValues = 
                    arrString.split ',' for arrString in Object.keys(@data) when 1 < arrString.split(',').length <= 3
                fact = @data[ngramSearch(tokStemmedKey, arrValues)]
        if resolveAlias and alias?
            fact = @get alias[1]
        fact
    
    search: (str) ->
        keys = Object.keys @data

        keys.filter (a) =>
            value = @data[a].value
            value.indexOf(str) > -1 || a.indexOf(str) > -1

    forget: (key) ->
        fact = @get key

        if fact
            fact.forgotten = true

    remember: (key) ->
        fact = @get key

        if fact
            fact.forgotten = false

        fact


    drop: (key) ->
        key = key.toLowerCase()
        if @get key, false
            delete @data[key]
        else false

tokenizeAndStem = (string) ->
    if string.length < 5
        string
    tokenizer = new natural.RegexpTokenizer pattern: /\_|\s|\.|\!|\'|\""/i
    natural.PorterStemmer.stem token for token in tokenizer.tokenize string
    
ngramSearch = (arrKey, arrValues) ->
    #reverse and search
    match = value for value in arrValues when ngramCompare arrKey, value or
    ngramCompare arrKey.reverse(), value

ngramCompare = (ngram1, ngram2) ->
    return true if ngram1[0] is ngram2[0] and 
    ngram1[ngram1.length - 1] is ngram2[ngram2.length - 1]
    return false

module.exports = Factoids
