import { NativeModules } from 'react-native';

interface ImageToVideoOptions {
  width: number;
  height: number;
  absolutePaths: Array<string>;
}

type ImagesToVideoType = {
  render(options: ImageToVideoOptions): Promise<string>;
};

const { ImagesToVideo } = NativeModules;

export default ImagesToVideo as ImagesToVideoType;
