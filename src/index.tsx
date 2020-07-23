import { NativeModules } from 'react-native';

type ImagesToVideoType = {
  multiply(a: number, b: number): Promise<number>;
};

const { ImagesToVideo } = NativeModules;

export default ImagesToVideo as ImagesToVideoType;
