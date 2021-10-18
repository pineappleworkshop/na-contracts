import NonFungibleToken from 0xNFT_CONTRACT_ADDRESS
import BlockRecordsSingle from 0xSERVICE_ACCOUNT_ADDRESS
import FungibleToken from 0xFUNGIBLE_TOKEN_CONTRACT_ADDRESS
import FUSD from 0xFUSD_CONTRACT_ADDRESS
import BlockRecordsStorefront from 0xSERVICE_ACCOUNT_ADDRESS
import BlockRecordsMarketplace from 0xSERVICE_ACCOUNT_ADDRESS
import BlockRecordsUser from 0xSERVICE_ACCOUNT_ADDRESS

transaction(
    name: String,
    description: String,
    tags: [String]
) {
    prepare(acct: AuthAccount) {
        // create BR Single collection
        if acct.borrow<&BlockRecordsSingle.Collection>(from: BlockRecordsSingle.CollectionStoragePath) == nil {
            let collection <- BlockRecordsSingle.createEmptyCollection()
            // save collection
            acct.save(<- collection, to: BlockRecordsSingle.CollectionStoragePath)
            // unlink if already exists
            // acct.unlink(BlockRecordsSingle.CollectionPublicPath)
            // collection public: collection is viewable
            acct.link<&{NonFungibleToken.CollectionPublic, BlockRecordsSingle.CollectionPublic}>(
                BlockRecordsSingle.CollectionPublicPath,
                target: BlockRecordsSingle.CollectionStoragePath
            )    
        }
            
        // create FUSD vault
        // todo: we can move this to another transaction in case the user already has an fusd vault
        // in the case that the user already has an FUSD vault saved at a different path
        let fusdVaultStoragePath = /storage/fusdVault
        let fusdVaultReceiverPublicPath = /public/fusdReceiver
        let fusdBalancePublicPath = /public/fusdBalance
        if acct.borrow<&FUSD.Vault>(from: fusdVaultStoragePath) == nil {
            // save FUSD vault
            acct.save(<- FUSD.createEmptyVault(), to: fusdVaultStoragePath)
            
            acct.link<&FUSD.Vault{FungibleToken.Receiver}>(
                fusdVaultReceiverPublicPath,
                target: fusdVaultStoragePath
            )
            // FUSD balance
            acct.link<&FUSD.Vault{FungibleToken.Balance}>(
                fusdBalancePublicPath,
                target: fusdVaultStoragePath
            )
        }
        
        // create storefront
        if acct.borrow<&BlockRecordsStorefront.Storefront>(from: BlockRecordsStorefront.StorefrontStoragePath) == nil {
            let storefront <- BlockRecordsStorefront.createStorefront() as! @BlockRecordsStorefront.Storefront
            // save storefront
            acct.save(<- storefront, to: BlockRecordsStorefront.StorefrontStoragePath)
            // storefront marketplace: to list on central marketplace for marketplace trades
            acct.link<&BlockRecordsStorefront.Storefront{BlockRecordsStorefront.StorefrontMarketplace}>(
                BlockRecordsStorefront.StorefrontMarketplacePath, 
                target: BlockRecordsStorefront.StorefrontStoragePath
            )
            // storefront public: for peer to peer trades
            acct.link<&BlockRecordsStorefront.Storefront{BlockRecordsStorefront.StorefrontPublic}>(
                BlockRecordsStorefront.StorefrontPublicPath, 
                target: BlockRecordsStorefront.StorefrontStoragePath
            )
            // storefront manager: for owner privs
            acct.link<&BlockRecordsStorefront.Storefront{BlockRecordsStorefront.StorefrontManager}>(
                BlockRecordsStorefront.StorefrontManagerPath, 
                target: BlockRecordsStorefront.StorefrontStoragePath
            )
        }

        // list storefront in central marketplace
        let storefrontCap = acct.getCapability<&BlockRecordsStorefront.Storefront{BlockRecordsStorefront.StorefrontMarketplace}>(BlockRecordsStorefront.StorefrontMarketplacePath)
        let marketplace = getAccount(0xSERVICE_ACCOUNT_ADDRESS).getCapability<&BlockRecordsMarketplace.Marketplace{BlockRecordsMarketplace.MarketplacePublic}>(BlockRecordsMarketplace.MarketplacePublicPath)!.borrow()!
        marketplace.listStorefront(storefrontCapability: storefrontCap, address: acct.address)

        // create user profile
        if acct.borrow<&BlockRecordsUser.User>(from: BlockRecordsUser.UserStoragePath) == nil {
            let user <- BlockRecordsUser.createUser(
                name: name, 
                description: description,
                allowStoringFollowers: true,
                tags: tags
            ) as! @BlockRecordsUser.User

            // save user profile
            acct.save(<- user, to: BlockRecordsUser.UserStoragePath)
            acct.link<&BlockRecordsUser.User{BlockRecordsUser.UserPublic}>(
                BlockRecordsUser.UserPublicPath, 
                target: BlockRecordsUser.UserStoragePath
            )
        }
    }
}