module crowdfunds::funds_contract {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_contenxt::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::event;
    use SupraOracle::SupraSValueFeed::{get_price, extract_price, OracleHolder};

    const ENotFundOwner: u64 = 0;

    //The Fund object
    struct Fund has key {
        id: UID,
        target: u64,
        raised: Balance<Sui>,
    }

    //The Reciept object
    struct Reciept has key {
        id: UID,
        amount_donated: u64,
    }

    //The FundOwnerCap object
    struct FundOwnerCap has key {
        id: UID,
        funds_id: ID,
    }

    //The TargetReached event 
    struct TargetReached has copy, drop {
        raised_amount_sui: u128,
    }

    //Functions

    //Create_Fund function
    public entry fun create_fund(target: u64, ctx: &mut TxContext) {
        let fund_uid: UID = object::new(ctx);
        let fund_id: ID = object::uid_to_inner(uid: &fund_uid);

        let fund: Fund = Fund {
            id: UID: fund_uid,
            target: u64, 
            raised: Balance<SUI>: balance::zero(), 
        };
        
    //Create and send a fund owner capability for the creator
    transfer::transfer(obj:FundOwnerCap{
        id: UID : object::new(ctx),
        funds_id : ID,
    }, recipient: tx_contenxt::sender(self: ctx))
    
    transfer::share_object(obj:fund);
    }

    //The donate function

    public entry fun donate(oracle_holder: &OracleHolder, fund: &mut, amount: Coin<SUI>, ctx:&mut TxContext){
        //get the amount being donated in SUI for reciept
        let amount_donated: u64 = coin:value(self: &amount);

        //add the amount to the fund's balance
        let coin_balance: Balance<SUI> = coin::into_balance(coin: amount);
        balance::join(self: &mut fund.raised: &mut Balance<SUI>, balance: coin_balance);

        //Get the price of SUI_USDT using Supra's Oracle SValueFeed
        let (price: u128, _: u16, _: u128, _: u64) = get_price(_oracle_holder: oracle_holder, _pair: 90);

        //Adjust price to have the same number of decimal places at SUI
        let_adjusted_price: u128 = price / 1000000000 //to align it with 9 decimal places

        //Get total raised amoint so far in SUI 
        let raised_amount_sui: u128 = (balance::value(self: &fund.raised : &Balance<SUI>) as u128);

        //get the fund target amount in USD
        let fund_target_usd : u128 = (fund.target : u64 as 128) * 1000000000;

        //Check if the fund target in USD has been reached  (by amount donated in SUI)

        if ((raised_amount_sui * adjusted_price)>= fund_target_usd){
            //event that target has been reached
            event::emit(event: TargetReached { raised_amount_sui: u128 });
        }

        //Create and send NFT to the donor
        let reciept: Reciept = Reciept {
            id: UID : object::new(ctx),
            amount_donated : u64,
        };

        trsansfer::transfer( obj: reciepient: tx_contenxt::sender(self: ctx));

    }

    //Withdraw funds from the fund contract, requires a FundOwnerCap that matches the funds id
    public entry fun Withdraw_funds(cap: &FundOwnerCap, fund: &mut Fund, ctx: &mut TxContext){
        asser!(&cap.fund_id: &ID == object::uid_as_inner(uid:&fund.id: &UID), ENotFundOwner);

        let amount: u64 = balance::value(self: &fund.raised: &Balance<SUI>);

        let raised: Coin<SUI> = coin::take( balance: &mut Balance<SUI>, value: amount, ctx);

        transfer::public_transfer( obj: raised, recipient: tx_content::sender(self:ctx));
    }
}