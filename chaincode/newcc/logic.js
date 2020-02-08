'use strict';
const { Contract} = require('fabric-contract-api');

class collections extends Contract {
   
  async queryProduct(ctx, collectionName,productId) {
    let productAsBytes = await ctx.stub.getPrivateData(collectionName,productId); 
    if (!productAsBytes || productAsBytes.toString().length <= 0) {
      throw new Error('Product does not exist: ');
    }
    let product =  JSON.parse(productAsBytes);
    return product;
  }

  

  async addProduct(ctx, collectionName, productId,name,price,seller) {
    console.info('============= START : Adding Product===========');

   let product = {
      ProductId: productId,
      Name: name,
      Price: price,
      Seller: seller
    };

    await ctx.stub.putPrivateData(collectionName,productId Buffer.from(JSON.stringify(product)));
    console.info('============= END : Private Product Added===========');
    return "Product Added.."
  }
};

module.exports = collections;