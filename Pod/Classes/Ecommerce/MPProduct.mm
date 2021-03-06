//
//  MPProduct.mm
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPProduct.h"
#import "MPConstants.h"
#include "MPHasher.h"
#import "NSDictionary+MPCaseInsensitive.h"

// Internal
NSString *const kMPProductBrand = @"br";
NSString *const kMPProductCouponCode = @"cc";
NSString *const kMPProductVariant = @"va";
NSString *const kMPProductPosition = @"ps";
NSString *const kMPProductAddedToCart = @"act";
NSString *const kMPProductName = @"nm";
NSString *const kMPProductSKU = @"id";
NSString *const kMPProductUnitPrice = @"pr";
NSString *const kMPProductQuantity = @"qt";
NSString *const kMPProductRevenue = @"tr";
NSString *const kMPProductCategory = @"ca";
NSString *const kMPProductTotalAmount = @"tpa";
NSString *const kMPProductTransactionId = @"ti";
NSString *const kMPProductAffiliation = @"ta";
NSString *const kMPProductCurrency = @"cu";
NSString *const kMPProductTax = @"tt";
NSString *const kMPProductShipping = @"ts";

// Expanded
NSString *const kMPExpProductBrand = @"Brand";
NSString *const kMPExpProductName = @"Name";
NSString *const kMPExpProductSKU = @"Id";
NSString *const kMPExpProductUnitPrice = @"Item Price";
NSString *const kMPExpProductQuantity = @"Quantity";
NSString *const kMPExpProductCategory = @"Category";
NSString *const kMPExpProductCouponCode = @"Coupon Code";
NSString *const kMPExpProductVariant = @"Variant";
NSString *const kMPExpProductPosition = @"Position";
NSString *const kMPExpProductTotalAmount = @"Total Product Amount";


@interface MPProduct()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *beautifiedAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *objectDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *userDefinedAttributes;

@end

@implementation MPProduct

@synthesize beautifiedAttributes = _beautifiedAttributes;
@synthesize userDefinedAttributes = _userDefinedAttributes;

- (instancetype)initWithName:(NSString *)name sku:(NSString *)sku quantity:(NSNumber *)quantity price:(NSNumber *)price {
    NSAssert(!MPIsNull(name), @"'name' is a required parameter.");
    NSAssert(!MPIsNull(sku), @"'sku' is a required parameter.");
    NSAssert(!MPIsNull(price), @"'price' is a required parameter.");
    
    self = [super init];
    if (!self || MPIsNull(name) || MPIsNull(sku) || MPIsNull(price)) {
        return nil;
    }
    
    self.name = name;
    self.sku = sku;
    self.quantity = quantity ? : @1;
    self.price = price;

    return self;
}

- (instancetype)initWithName:(NSString *)name category:(NSString *)category quantity:(NSInteger)quantity totalAmount:(double)totalAmount {
    self = [self initWithName:name sku:@"No SKU" quantity:@(quantity) price:@0];
    if (!self) {
        return nil;
    }
    
    if (category) {
        self.category = category;
    }
    
    if (totalAmount != 0.0) {
        self.totalAmount = totalAmount;
    }
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendString:@"MPProduct {\n"];
    
    [_objectDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [description appendFormat:@"  %@ : %@\n", key, obj];
    }];
    
    [_userDefinedAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [description appendFormat:@"  %@ : %@\n", key, obj];
    }];
    
    [description appendString:@"}\n"];

    return description;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MPProduct class]]) {
        return NO;
    }
    
    return [_objectDictionary isEqualToDictionary:((MPProduct *)object)->_objectDictionary];
}

#pragma mark Private accessors
- (NSMutableDictionary<NSString *, id> *)beautifiedAttributes {
    if (_beautifiedAttributes) {
        return _beautifiedAttributes;
    }
    
    _beautifiedAttributes = [[NSMutableDictionary alloc] initWithCapacity:4];
    return _beautifiedAttributes;
}

- (NSMutableDictionary<NSString *, id> *)objectDictionary {
    if (_objectDictionary) {
        return _objectDictionary;
    }
    
    _objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    return _objectDictionary;
}

- (NSMutableDictionary<NSString *, id> *)userDefinedAttributes {
    if (_userDefinedAttributes) {
        return _userDefinedAttributes;
    }
    
    _userDefinedAttributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _userDefinedAttributes;
}

#pragma mark Private methods
- (void)calculateTotalAmount {
    double quantity = [self.quantity doubleValue] > 0 ? : 1;
    NSNumber *totalAmount = @(quantity * [self.price doubleValue]);
    
    self.objectDictionary[kMPProductTotalAmount] = totalAmount;
    self.beautifiedAttributes[kMPExpProductTotalAmount] = totalAmount;
}

#pragma mark Subscripting
- (id)objectForKeyedSubscript:(NSString *const)key {
    NSAssert(key != nil, @"'key' cannot be nil.");

    id object = [self.userDefinedAttributes objectForKey:key];
    
    if (!object) {
        object = [self.objectDictionary objectForKey:key];
    }
    
    return object;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    NSAssert(key != nil, @"'key' cannot be nil.");
    NSAssert(obj != nil, @"'obj' cannot be nil.");
    
    if (obj == nil) {
        return;
    }
    
    [self.userDefinedAttributes setObject:obj forKey:key];
}

- (NSArray *)allKeys {
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    if (_objectDictionary) {
        [keys addObjectsFromArray:[_objectDictionary allKeys]];
    }
    
    if (_userDefinedAttributes) {
        [keys addObjectsFromArray:[_userDefinedAttributes allKeys]];
    }
    
    return (NSArray *)keys;
}

- (NSUInteger)count {
    NSUInteger count = self.objectDictionary.count + self.userDefinedAttributes.count;
    return count;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPProduct *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_beautifiedAttributes = _beautifiedAttributes ? [[NSMutableDictionary alloc] initWithDictionary:[_beautifiedAttributes copy]] : nil;
        copyObject->_objectDictionary = _objectDictionary ? [[NSMutableDictionary alloc] initWithDictionary:[_objectDictionary copy]] : nil;
        copyObject->_userDefinedAttributes = _userDefinedAttributes ? [[NSMutableDictionary alloc] initWithDictionary:[_userDefinedAttributes copy]] : nil;
    }
    
    return copyObject;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (_beautifiedAttributes) {
        [coder encodeObject:_beautifiedAttributes forKey:@"beautifiedAttributes"];
    }
    
    if (_objectDictionary) {
        [coder encodeObject:_objectDictionary forKey:@"productDictionary"];
    }
    
    if (_userDefinedAttributes) {
        [coder encodeObject:_userDefinedAttributes forKey:@"userDefinedAttributes"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    
    NSDictionary *dictionary;
    
    dictionary = [coder decodeObjectForKey:@"beautifiedAttributes"];
    if (dictionary) {
        self->_beautifiedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    dictionary = [coder decodeObjectForKey:@"productDictionary"];
    if (dictionary) {
        self->_objectDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    dictionary = [coder decodeObjectForKey:@"userDefinedAttributes"];
    if (dictionary) {
        self->_userDefinedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    return self;
}

#pragma mark MPProduct+Dictionary
- (NSDictionary<NSString *, id> *)commerceDictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *commerceDictionary = [[NSMutableDictionary alloc] init];
    
    if (_userDefinedAttributes) {
        commerceDictionary[@"attrs"] = [_userDefinedAttributes transformValuesToString];
    }
    
    if (_objectDictionary) {
        [commerceDictionary addEntriesFromDictionary:[_objectDictionary transformValuesToString]];
    }
    
    return commerceDictionary.count > 0 ? (NSDictionary *)commerceDictionary : nil;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
    
    if (_objectDictionary) {
        [dictionary addEntriesFromDictionary:[_objectDictionary transformValuesToString]];
    }
    
    if (_userDefinedAttributes) {
        [dictionary addEntriesFromDictionary:[_userDefinedAttributes transformValuesToString]];
    }
    
    return dictionary.count > 0 ? (NSDictionary *)dictionary : nil;
}

- (NSDictionary<NSString *, id> *)beautifiedDictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
    
    if (_beautifiedAttributes) {
        [dictionary addEntriesFromDictionary:[_beautifiedAttributes transformValuesToString]];
    }
    
    if (_userDefinedAttributes) {
        [dictionary addEntriesFromDictionary:[_userDefinedAttributes transformValuesToString]];
    }
    
    return dictionary.count > 0 ? (NSDictionary *)dictionary : nil;
}

- (NSDictionary<NSString *, id> *)legacyDictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
    
    if (_userDefinedAttributes) {
        [dictionary addEntriesFromDictionary:_userDefinedAttributes];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dictionary[@"TransactionAffiliation"] = self.affiliation ? : @"No Affiliation";
    dictionary[@"ProductCategory"] = self.category ? : @"No Category";
    dictionary[@"CurrencyCode"] = self.currency ? : @"USD";
    dictionary[@"ProductName"] = self.name ? : @"No Name";
    dictionary[@"ProductSKU"] = self.sku ? : @"No SKU";
    dictionary[@"ProductUnitPrice"] = self.price ? : @0;
    dictionary[@"ProductQuantity"] = self.quantity ? : @1;
    dictionary[@"TransactionID"] = self.transactionId ? : [[NSUUID UUID] UUIDString];
    
    if (self.totalAmount != 0.0) {
        dictionary[@"RevenueAmount"] = @(self.totalAmount);
    }
    
    if (self.taxAmount != 0.0) {
        dictionary[@"TaxAmount"] = @(self.taxAmount);
    }
    
    if (self.shippingAmount != 0.0) {
        dictionary[@"ShippingAmount"] = @(self.shippingAmount);
    }
#pragma clang diagnostic pop
    
    return (NSDictionary *)dictionary;
}

- (void)setTimeAddedToCart:(NSDate *)date {
    if (date) {
        self.objectDictionary[kMPProductAddedToCart] = MPMilliseconds([date timeIntervalSince1970]);
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductAddedToCart];
    }
}

- (MPProduct *)copyMatchingHashedProperties:(NSDictionary *)hashedMap {
    __block MPProduct *copyProduct = [self copy];
    __block NSString *hashedKey;
    __block id hashedValue;
    NSNumber *const zero = @0;
    
    [_beautifiedAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        hashedKey = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        hashedValue = hashedMap[hashedKey];
        
        if ([hashedValue isEqualToNumber:zero]) {
            [copyProduct->_beautifiedAttributes removeObjectForKey:key];
        }
    }];
    
    [_userDefinedAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        hashedKey = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        hashedValue = hashedMap[hashedKey];
        
        if ([hashedValue isEqualToNumber:zero]) {
            [copyProduct->_userDefinedAttributes removeObjectForKey:key];
        }
    }];
    
    return copyProduct;
}

#pragma mark Public accessors
- (NSString *)affiliation {
    return self.objectDictionary[kMPProductAffiliation];
}

- (void)setAffiliation:(NSString *)affiliation {
    if (affiliation) {
        self.objectDictionary[kMPProductAffiliation] = affiliation;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductAffiliation];
    }
}

- (NSString *)brand {
    return self.objectDictionary[kMPProductBrand];
}

- (void)setBrand:(NSString *)brand {
    if (brand) {
        self.objectDictionary[kMPProductBrand] = brand;
        self.beautifiedAttributes[kMPExpProductBrand] = brand;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductBrand];
        [self.beautifiedAttributes removeObjectForKey:kMPExpProductBrand];
    }
}

- (NSString *)category {
    return self.objectDictionary[kMPProductCategory];
}

- (void)setCategory:(NSString *)category {
    if (category) {
        self.objectDictionary[kMPProductCategory] = category;
        self.beautifiedAttributes[kMPExpProductCategory] = category;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductCategory];
        [self.beautifiedAttributes removeObjectForKey:kMPExpProductCategory];
    }
}

- (NSString *)couponCode {
    return self.objectDictionary[kMPProductCouponCode];
}

- (void)setCouponCode:(NSString *)couponCode {
    if (couponCode) {
        self.objectDictionary[kMPProductCouponCode] = couponCode;
        self.beautifiedAttributes[kMPExpProductCouponCode] = couponCode;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductCouponCode];
        [self.beautifiedAttributes removeObjectForKey:kMPExpProductCouponCode];
    }
}

- (NSString *)currency {
    return self.objectDictionary[kMPProductCurrency];
}

- (void)setCurrency:(NSString *)currency {
    self.objectDictionary[kMPProductCurrency] = currency ? : @"USD";
}

- (NSString *)name {
    return self.objectDictionary[kMPProductName];
}

- (void)setName:(NSString *)name {
    NSAssert(!MPIsNull(name), @"'name' is a required property.");
    
    if (name) {
        self.objectDictionary[kMPProductName] = name;
        self.beautifiedAttributes[kMPExpProductName] = name;
    }
}

- (NSNumber *)price {
    return self.objectDictionary[kMPProductUnitPrice];
}

- (void)setPrice:(NSNumber *)price {
    NSAssert(!MPIsNull(price), @"'price' is a required property. Use @0 if the product does not have a price.");
    NSAssert([price isKindOfClass:[NSNumber class]], @"'price' must be a number.");

    if (price && [price isKindOfClass:[NSNumber class]]) {
        self.objectDictionary[kMPProductUnitPrice] = price;
        self.beautifiedAttributes[kMPExpProductUnitPrice] = price;
        [self calculateTotalAmount];
    }
}

- (NSString *)sku {
    return self.objectDictionary[kMPProductSKU];
}

- (void)setSku:(NSString *)sku {
    NSAssert(!MPIsNull(sku), @"'sku' is a required property.");
    
    if (sku) {
        self.objectDictionary[kMPProductSKU] = sku;
        self.beautifiedAttributes[kMPExpProductSKU] = sku;
    }
}

- (NSString *)transactionId {
    return self.objectDictionary[kMPProductTransactionId];
}

- (void)setTransactionId:(NSString *)transactionId {
    if (transactionId) {
        self.objectDictionary[kMPProductTransactionId] = transactionId;
    }
}

- (NSString *)variant {
    return self.objectDictionary[kMPProductVariant];
}

- (void)setVariant:(NSString *)variant {
    if (variant) {
        self.objectDictionary[kMPProductVariant] = variant;
        self.beautifiedAttributes[kMPExpProductVariant] = variant;
    }
}

- (double)shippingAmount {
    return [self.objectDictionary[kMPProductShipping] doubleValue];
}

- (void)setShippingAmount:(double)shippingAmount {
    self.objectDictionary[kMPProductShipping] = @(shippingAmount);
}

- (double)taxAmount {
    return [self.objectDictionary[kMPProductTax] doubleValue];
}

- (void)setTaxAmount:(double)taxAmount {
    self.objectDictionary[kMPProductTax] = @(taxAmount);
}

- (double)totalAmount {
    return [self.objectDictionary[kMPProductRevenue] doubleValue];
}

- (void)setTotalAmount:(double)totalAmount {
    self.objectDictionary[kMPProductRevenue] = @(totalAmount);
}

- (double)unitPrice {
    return [self.price doubleValue];
}

- (void)setUnitPrice:(double)unitPrice {
    self.price = @(unitPrice);
}

- (NSUInteger)position {
    return [self.objectDictionary[kMPProductPosition] integerValue];
}

- (void)setPosition:(NSUInteger)position {
    NSNumber *positionNumber = @(position);
    self.objectDictionary[kMPProductPosition] = positionNumber;
    self.beautifiedAttributes[kMPExpProductPosition] = positionNumber;
}

- (NSNumber *)quantity {
    return self.objectDictionary[kMPProductQuantity];
}

- (void)setQuantity:(NSNumber *)quantity {
    NSAssert(!MPIsNull(quantity), @"'quantity' is a required property.");
    NSAssert([quantity isKindOfClass:[NSNumber class]], @"'quantity' must be a number.");

    if (quantity && [quantity isKindOfClass:[NSNumber class]]) {
        self.objectDictionary[kMPProductQuantity] = quantity;
        self.beautifiedAttributes[kMPExpProductQuantity] = quantity;
        [self calculateTotalAmount];
        
        if (self.objectDictionary[kMPProductAddedToCart]) {
            [self setTimeAddedToCart:[NSDate date]];
        }
    }
}

@end
