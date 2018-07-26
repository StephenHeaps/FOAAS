//
//  FOAAS.swift
//  FOAAS
//
//  Created by Stephen Heaps on 2018-07-25.
//  Copyright © 2018 Stephen Heaps. All rights reserved.
//

import Foundation
import UIKit

enum FOAASError: Error {
    case zeroOperationsFound
    case failedToBuildURL
    case failedToFindValidRandom
    case dataIsNil
    case failedToValidateReponse
}

struct FOAASResponse: Codable {
    var message: String
    var subtitle: String
}

struct FOAASOperation: Codable {
    var name: String
    var url: URL
    var fields: [FOAASField]
}

struct FOAASField: Codable {
    var name: String
    var field: String
}

class FOAAS {
    let baseURLString = "https://www.foaas.com"
    var baseURL: URL
    
    init() {
        guard let url = URL(string: baseURLString) else { fatalError() }
        self.baseURL = url
    }
    
    // /operations     Will return a JSON list of operations with names and fields. Note: JSON Only
    func fetchAllOperations(completion: (([FOAASOperation], Error?)->Void)?) {
        let operationsURL: URL = baseURL.appendingPathComponent("operations")
        let task = URLSession.shared.dataTask(with: operationsURL) {(data, response, error) in
            if let error = error {
                completion?([], error)
                return
            }
            guard let content = data else {
                let error = FOAASError.dataIsNil
                completion?([], error)
                return
            }
            
            var operations: [FOAASOperation] = []
            let decoder = JSONDecoder()
            do {
                operations = try decoder.decode([FOAASOperation].self, from: content)
            } catch {
                print("error trying to convert data to JSON")
                print(error)
                completion?(operations, error)
                return
            }
            
            completion?(operations, nil)
        }
        
        task.resume()
    }
    
    // provide a name to only choose functions with 2 parameters (name: String, from: String, completion...)
    // provide nil for name to only choose functions with a single parameter
    func random(name: String?, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        self.fetchAllOperations { (operations, error) in
            if let error = error {
                completion?(nil, error)
                return
            }
            if operations.isEmpty {
                let error = FOAASError.zeroOperationsFound
                completion?(nil, error)
                return
            }
            if let name = name {
                let nameAndFromOperations = operations.compactMap({ (operation) -> FOAASOperation? in
                    if operation.fields.count == 2 {
                        if let first = operation.fields.first, first.field == "name",
                            let last = operation.fields.last, last.field == "from" {
                            return operation
                        }
                    }
                    return nil
                })
                if let randomOperation = nameAndFromOperations.randomElement(), randomOperation.fields.count == 2,
                    let field1 = randomOperation.fields.first, let field2 = randomOperation.fields.last {
                    
                    var URLString = randomOperation.url.relativePath.replacingOccurrences(of: ":\(field1.field)", with: name, options: String.CompareOptions.literal, range: nil)
                    URLString = URLString.replacingOccurrences(of: ":\(field2.field)", with: from, options: .literal, range: nil)
                    URLString = self.baseURLString + URLString
                    if let URL = URL(string: URLString) {
                        self.fetchResponse(url: URL, completion: completion)
                        return // complete
                    } else {
                        let error = FOAASError.failedToBuildURL
                        completion?(nil, error)
                        return
                    }
                } else {
                    let error = FOAASError.failedToFindValidRandom
                    completion?(nil, error)
                    return
                }
            } else { // random only functions with 1 parameter
                let fromOperations = operations.compactMap({ (operation) -> FOAASOperation? in
                    if operation.fields.count == 1 {
                        if let first = operation.fields.first, first.field == "from" {
                            return operation
                        }
                    }
                    return nil
                })
                if let randomOperation = fromOperations.randomElement(), randomOperation.fields.count == 1,
                    let field1 = randomOperation.fields.first {
                    
                    var URLString = randomOperation.url.relativePath.replacingOccurrences(of: ":\(field1.field)", with: from, options: String.CompareOptions.literal, range: nil)
                    URLString = self.baseURLString + URLString
                    if let URL = URL(string: URLString) {
                        self.fetchResponse(url: URL, completion: completion)
                        return // complete
                    } else {
                        let error = FOAASError.failedToBuildURL
                        completion?(nil, error)
                        return
                    }
                } else {
                    let error = FOAASError.failedToFindValidRandom
                    completion?(nil, error)
                    return
                }
            }
        }
    }
    
    func fetchResponse(url: URL, completion: ((FOAASResponse?, Error?)->Void)?) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let error = error {
                // error
                completion?(nil, error)
                return
            }
            guard let content = data else {
                let error = FOAASError.zeroOperationsFound
                completion?(nil, error)
                return
            }
            var response: FOAASResponse?
            let decoder = JSONDecoder()
            do {
                response = try decoder.decode(FOAASResponse.self, from: content)
            } catch {
                completion?(nil, error)
            }
            if let response = response {
                completion?(response, nil)
            } else {
                let error = FOAASError.failedToValidateReponse
                completion?(nil, error)
            }
        }
        
        task.resume()
    }
    
//    // /version     Will return content with the current FOAAS version number.
//    func version(completion: (()->Void)?) {
//
//    }
    
    // /anyway/:company/:from    Will return content of the form 'Who the fuck are you anyway, :company, why are you stirring up so much trouble, and, who pays you? - :from'
    func anyway(company: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("anyway").appendingPathComponent(company).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /asshole/:from    Will return content of the form 'Fuck you, asshole. - :from'
    func asshole(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("asshole").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /awesome/:from    Will return content of the form 'This is Fucking Awesome. - :from'
    func awesome(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("awesome").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /back/:name/:from    Will return content of the form ':name, back the fuck off. - :from'
    func back(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("awesome").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /bag/:from    Will return content of the form 'Eat a bag of fucking dicks. - :from'
    func bag(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("bag").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /ballmer/:name/:company/:from    Will return content of the form 'Fucking :name is a fucking pussy. I'm going to fucking bury that guy, I have done it before, and I will do it again. I'm going to fucking kill :company. - :from'
    func ballmer(name: String, company: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("awesome").appendingPathComponent(name).appendingPathComponent(company).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /bday/:name/:from    Will return content of the form 'Happy Fucking Birthday, :name. - :from'
    func bday(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("bday").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /because/:from    Will return content of the form 'Why? Because fuck you, that's why. - :from'
    func because(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("because").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /blackadder/:name/:from    Will return content of the form ':name, your head is as empty as a eunuch’s underpants. Fuck off! - :from'
    func blackadder(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("blackadder").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /bm/:name/:from    Will return content of the form 'Bravo mike, :name. - :from'
    func bm(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("bm").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /bucket/:from    Will return content of the form 'Please choke on a bucket of cocks. - :from'
    func bucket(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("bucket").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /bus/:name/:from    Will return content of the form 'Christ on a bendy-bus, :name, don't be such a fucking faff-arse. - :from'
    func bus(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("bus").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /bye/:from    Will return content of the form 'Fuckity bye! - :from'
    func bye(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("bye").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /caniuse/:tool/:from    Will return content of the form 'Can you use :tool? Fuck no! - :from'
    func caniuse(tool: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("caniuse").appendingPathComponent(tool).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /chainsaw/:name/:from    Will return content of the form 'Fuck me gently with a chainsaw, :name. Do I look like Mother Teresa? - :from'
    func chainsaw(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("chainsaw").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /cocksplat/:name/:from    Will return content of the form 'Fuck off :name, you worthless cocksplat - :from'
    func cocksplat(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("cocksplat").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /cool/:from    Will return content of the form 'Cool story, bro. - :from'
    func cool(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("cool").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /cup/:from    Will return content of the form 'How about a nice cup of shut the fuck up? - :from'
    func cup(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("cup").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /dalton/:name/:from    Will return content of the form ':name: A fucking problem solving super-hero. - :from'
    func dalton(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("dalton").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /deraadt/:name/:from    Will return content of the form ':name you are being the usual slimy hypocritical asshole... You may have had value ten years ago, but people will see that you don't anymore. - :from'
    func deraadt(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("deraadt").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /donut/:name/:from    Will return content of the form ':name, go and take a flying fuck at a rolling donut. - :from'
    func donut(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("donut").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /dosomething/:do/:something/:from    Will return content of the form ':do the fucking :something! - :from'
    func dosomething(doString: String, something: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("dosomething").appendingPathComponent(doString).appendingPathComponent(something).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /equity/:name/:from    Will return content of the form 'Equity only? Long hours? Zero Pay? Well :name, just sign me right the fuck up. - :from'
    func equity(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("equity").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /everyone/:from    Will return content of the form 'Everyone can go and fuck off. - :from'
    func everyone(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("everyone").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /everything/:from    Will return content of the form 'Fuck everything. - :from'
    func everything(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("everything").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /family/:from    Will return content of the form 'Fuck you, your whole family, your pets, and your feces. - :from'
    func family(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("family").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /fascinating/:from    Will return content of the form 'Fascinating story, in what chapter do you shut the fuck up? - :from'
    func fascinating(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("fascinating").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /field/:name/:from/:reference    Will return content of the form 'And :name said unto :from, 'Verily, cast thine eyes upon the field in which I grow my fucks', and :from gave witness unto the field, and saw that it was barren. - :reference'
    func field(name: String, from: String, reference: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("field").appendingPathComponent(name).appendingPathComponent(from).appendingPathComponent(reference)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /flying/:from    Will return content of the form 'I don't give a flying fuck. - :from'
    func flying(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("flying").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /fts/:name/:from    Will return content of the form 'Fuck that shit, :name. - :from'
    func fts(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("fts").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /fyyff/:from    Will return content of the form 'Fuck you, you fucking fuck. - :from'
    func fyyff(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("fyyff").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /gfy/:name/:from    Will return content of the form 'Golf foxtrot yankee, :name. - :from'
    func gfy(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("gfy").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /give/:from    Will return content of the form 'I give zero fucks. - :from'
    func give(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("give").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /greed/:noun/:from    Will return content of the form 'The point is, ladies and gentleman, that :noun -- for lack of a better word -- is good. :noun is right. :noun works. :noun clarifies, cuts through, and captures the essence of the evolutionary spirit. :noun, in all of its forms -- :noun for life, for money, for love, knowledge -- has marked the upward surge of mankind. - :from'
    func greed(noun: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("greed").appendingPathComponent(noun).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /horse/:from    Will return content of the form 'Fuck you and the horse you rode in on. - :from'
    func horse(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("horse").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    //  /immensity/:from    Will return content of the form 'You can not imagine the immensity of the FUCK I do not give. - :from'
    func immensity(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("immensity").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /ing/:name/:from    Will return content of the form 'Fucking fuck off, :name. - :from'
    func ing(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("ing").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /keep/:name/:from    Will return content of the form ':name: Fuck off. And when you get there, fuck off from there too. Then fuck off some more. Keep fucking off until you get back here. Then fuck off again. - :from'
    func keep(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("keep").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /keepcalm/:reaction/:from    Will return content of the form 'Keep the fuck calm and :reaction! - :from'
    func keepcalm(reaction: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("keepcalm").appendingPathComponent(reaction).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /king/:name/:from    Will return content of the form 'Oh fuck off, just really fuck off you total dickface. Christ, :name, you are fucking thick. - :from'
    func king(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("king").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /life/:from    Will return content of the form 'Fuck my life. - :from'
    func life(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("life").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /linus/:name/:from    Will return content of the form ':name, there aren't enough swear-words in the English language, so now I'll have to call you perkeleen vittupää just to express my disgust and frustration with this crap. - :from'
    func linus(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("linus").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /look/:name/:from    Will return content of the form ':name, do I look like I give a fuck? - :from'
    func look(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("look").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /looking/:from    Will return content of the form 'Looking for a fuck to give. - :from'
    func looking(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("looking").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /madison/:name/:from    Will return content of the form 'What you've just said is one of the most insanely idiotic things I have ever heard, :name. At no point in your rambling, incoherent response were you even close to anything that could be considered a rational thought. Everyone in this room is now dumber for having listened to it. I award you no points :name, and may God have mercy on your soul. - :from'
    func madison(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("madison").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /maybe/:from    Will return content of the form 'Maybe. Maybe not. Maybe fuck yourself. - :from'
    func maybe(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("maybe").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /me/:from    Will return content of the form 'Fuck me. - :from'
    func me(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("me").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    
    // /mornin/:from    Will return content of the form 'Happy fuckin' mornin'! - :from'
    func mornin(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("mornin").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /no/:from    Will return content of the form 'No fucks given. - :from'
    func no(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("no").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /nugget/:name/:from    Will return content of the form 'Well :name, aren't you a shining example of a rancid fuck-nugget. - :from'
    func nugget(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("nugget").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /off/:name/:from    Will return content of the form 'Fuck off, :name. - :from'
    func off(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("off").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /off-with/:behavior/:from    Will return content of the form 'Fuck off with :behavior - :from'
    func offWith(behavior: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("off-with").appendingPathComponent(behavior).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /outside/:name/:from    Will return content of the form ':name, why don't you go outside and play hide-and-go-fuck-yourself? - :from'
    func outside(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("outside").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /particular/:thing/:from    Will return content of the form 'Fuck this :thing in particular. - :from'
    func particular(thing: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("particular").appendingPathComponent(thing).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /pink/:from    Will return content of the form 'Well, fuck me pink. - :from'
    func pink(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("pink").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /problem/:name/:from    Will return content of the form 'What the fuck is your problem :name? - :from'
    func problem(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("problem").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /programmer/:from    Will return content of the form 'Fuck you, I'm a programmer, bitch! - :from'
    func programmer(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("programmer").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /pulp/:language/:from    Will return content of the form ':language, motherfucker, do you speak it? - :from'
    func pulp(language: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("pulp").appendingPathComponent(language).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /question/:from    Will return content of the form 'To fuck off, or to fuck off (that is not a question) - :from'
    func question(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("question").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /retard/:from    Will return content of the form 'You Fucktard! - :from'
    func retard(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("retard").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /ridiculous/:from    Will return content of the form 'That's fucking ridiculous - :from'
    func ridiculous(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("ridiculous").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /rtfm/:from    Will return content of the form 'Read the fucking manual! - :from'
    func rtfm(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("rtfm").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /sake/:from    Will return content of the form 'For Fuck's sake! - :from'
    func sake(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("sake").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /shakespeare/:name/:from    Will return content of the form ':name, Thou clay-brained guts, thou knotty-pated fool, thou whoreson obscene greasy tallow-catch! - :from'
    func shakespeare(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("shakespeare").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /shit/:from    Will return content of the form 'Fuck this shit! - :from'
    func shit(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("shit").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /shutup/:name/:from    Will return content of the form ':name, shut the fuck up. - :from'
    func shutup(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("shutup").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /single/:from    Will return content of the form 'Not a single fuck was given. - :from'
    func single(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("single").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /thanks/:from    Will return content of the form 'Fuck you very much. - :from'
    func thanks(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("thanks").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /that/:from    Will return content of the form 'Fuck that. - :from'
    func that(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("that").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /think/:name/:from    Will return content of the form ':name, you think I give a fuck? - :from'
    func think(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("think").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /thinking/:name/:from    Will return content of the form ':name, what the fuck were you actually thinking? - :from'
    func thinking(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("thinking").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /this/:from    Will return content of the form 'Fuck this. - :from'
    func this(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("this").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /thumbs/:name/:from    Will return content of the form 'Who has two thumbs and doesn't give a fuck? :name. - :from'
    func thumbs(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("thumbs").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /too/:from    Will return content of the form 'Thanks, fuck you too. - :from'
    func too(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("too").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /tucker/:from    Will return content of the form 'Come the fuck in or fuck the fuck off. - :from'
    func tucker(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("tucker").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /version    Will return content of the form 'Version 2.0.0 FOAAS'
    func version(completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("version")
        self.fetchResponse(url: url, completion: completion)
    }
    // /what/:from    Will return content of the form 'What the fuck‽ - :from'
    func what(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("what").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /xmas/:name/:from    Will return content of the form 'Merry Fucking Christmas, :name. - :from'
    func xmas(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("xmas").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /yoda/:name/:from    Will return content of the form 'Fuck off, you must, :name. - :from'
    func yoda(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("yoda").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /you/:name/:from    Will return content of the form 'Fuck you, :name. - :from'
    func you(name: String, from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("you").appendingPathComponent(name).appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /zayn/:from    Will return content of the form 'Ask me if I give a motherfuck ?!! - :from'
    func zayn(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("zayn").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
    // /zero/:from    Will return content of the form 'Zero, thats the number of fucks I give. - :from'
    func zero(from: String, completion: ((FOAASResponse?, Error?)->Void)?) {
        let url = self.baseURL.appendingPathComponent("zero").appendingPathComponent(from)
        self.fetchResponse(url: url, completion: completion)
    }
}
