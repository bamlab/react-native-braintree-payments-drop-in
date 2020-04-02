declare module 'react-native-braintree-payments-drop-in' {
  export interface ShowOptions {
    clientToken: string;
    threeDSecure?: {
      amount: number;
    };
  }

  export interface ShowResult {
    nonce: string;
    description: string;
    type: string;
    isDefault: boolean;
  }

  export default class BraintreeDropIn {
    public static show(options: ShowOptions): Promise<ShowResult>;
  }
}
