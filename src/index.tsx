import { NativeModules } from 'react-native';

interface ImageToVideoOptions {
  screenTimePerImage: number;
  width: number;
  height: number;
  absolutePaths: Array<string>;
}

type ImagesToVideoType = {
  render(options: ImageToVideoOptions): Promise<string>;
};

const { ImagesToVideo } = NativeModules;

export default ImagesToVideo as ImagesToVideoType;
